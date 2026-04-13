module UserBooks
  class CreateService
    def self.call(current_user:, isbn:, content: nil, tags: [], purchase_links: [])
      validate_params!(isbn, content, tags, purchase_links)

      book = Book.find_by(isbn: isbn) || fetch_and_create_book!(isbn)

      raise BookAlreadyRegisteredError if UserBook.exists?(user: current_user, book: book)

      ActiveRecord::Base.transaction do
        user_book = UserBook.create!(user: current_user, book: book, content: content)

        if tags.any?
          tag_records = Tag.where(name: tags)
          raise ValidationError, I18n.t("user_books.errors.invalid_tag_included") if tag_records.count != tags.uniq.length

          tag_records.each { |tag| UserBookTag.create!(user_book: user_book, tag: tag) }
        end

        purchase_links.each do |url|
          UserBookPurchaseLink.create!(user_book: user_book, url: url)
        end
      end

      Rails.logger.info "UserBooks::CreateService: user_id=#{current_user.id} isbn=#{isbn} 書籍を本棚に追加しました"
    end

    def self.validate_params!(isbn, content, tags, purchase_links)
      raise ValidationError, I18n.t("user_books.errors.isbn_invalid") unless isbn.to_s.match?(/\A\d{13}\z/)
      raise ValidationError, I18n.t("user_books.errors.content_too_long", count: UserBookConstants::MAX_CONTENT_LENGTH) if content && content.length > UserBookConstants::MAX_CONTENT_LENGTH
      raise ValidationError, I18n.t("user_books.errors.tags_too_many", count: UserBookConstants::MAX_TAGS) if tags.length > UserBookConstants::MAX_TAGS
      raise ValidationError, I18n.t("user_books.errors.purchase_links_too_many", count: UserBookConstants::MAX_PURCHASE_LINKS) if purchase_links.length > UserBookConstants::MAX_PURCHASE_LINKS

      purchase_links.each do |url|
        raise ValidationError, I18n.t("user_books.errors.purchase_link_url_invalid") unless url.match?(/\Ahttps?:\/\/.+/i)
        raise ValidationError, I18n.t("user_books.errors.purchase_link_url_too_long", count: UserBookConstants::MAX_PURCHASE_LINK_LENGTH) if url.length > UserBookConstants::MAX_PURCHASE_LINK_LENGTH
      end
    end
    private_class_method :validate_params!

    def self.fetch_and_create_book!(isbn)
      Rails.logger.info "UserBooks::CreateService: isbn=#{isbn} 楽天書籍APIから取得します"
      result = RakutenBooksClient.find_by_isbn(isbn: isbn)
      item = result[:Items]&.first
      raise RecordNotFoundError unless item

      Book.create!(
        isbn:          item[:isbn],
        title:         item[:title],
        authors:       item[:author]&.split("／") || [],
        thumbnail_url: item[:largeImageUrl]
      )
    end
    private_class_method :fetch_and_create_book!
  end
end

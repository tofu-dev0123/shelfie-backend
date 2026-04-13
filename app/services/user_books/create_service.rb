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
          raise ValidationError, Messages::UserBooks::INVALID_TAG_INCLUDED if tag_records.count != tags.uniq.length

          tag_records.each { |tag| UserBookTag.create!(user_book: user_book, tag: tag) }
        end

        purchase_links.each do |url|
          UserBookPurchaseLink.create!(user_book: user_book, url: url)
        end
      end

      Rails.logger.info "UserBooks::CreateService: user_id=#{current_user.id} isbn=#{isbn} 書籍を本棚に追加しました"
    end

    def self.validate_params!(isbn, content, tags, purchase_links)
      raise ValidationError, Messages::UserBooks::ISBN_INVALID unless isbn.to_s.match?(/\A\d{13}\z/)
      raise ValidationError, Messages::UserBooks::CONTENT_TOO_LONG if content && content.length > UserBookConstants::MAX_CONTENT_LENGTH
      raise ValidationError, Messages::UserBooks::TAGS_TOO_MANY if tags.length > UserBookConstants::MAX_TAGS
      raise ValidationError, Messages::UserBooks::PURCHASE_LINKS_TOO_MANY if purchase_links.length > UserBookConstants::MAX_PURCHASE_LINKS

      purchase_links.each do |url|
        raise ValidationError, Messages::UserBooks::PURCHASE_LINK_URL_INVALID unless url.match?(/\Ahttps?:\/\/.+/i)
        raise ValidationError, Messages::UserBooks::PURCHASE_LINK_URL_TOO_LONG if url.length > UserBookConstants::MAX_PURCHASE_LINK_LENGTH
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

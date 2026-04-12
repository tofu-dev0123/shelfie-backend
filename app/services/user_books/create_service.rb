module UserBooks
  class CreateService
    MAX_CONTENT_LENGTH       = 1000
    MAX_TAGS                 = 5
    MAX_PURCHASE_LINKS       = 3
    MAX_PURCHASE_LINK_LENGTH = 1000

    def self.call(current_user:, isbn:, content: nil, tags: [], purchase_links: [])
      validate_params!(isbn, content, tags, purchase_links)

      book = Book.find_by(isbn: isbn) || fetch_and_create_book!(isbn)

      raise BookAlreadyRegisteredError if UserBook.exists?(user: current_user, book: book)

      ActiveRecord::Base.transaction do
        user_book = UserBook.create!(user: current_user, book: book, content: content)

        if tags.any?
          tag_records = Tag.where(name: tags)
          raise ValidationError, "存在しないタグが含まれています" if tag_records.count != tags.uniq.length

          tag_records.each { |tag| UserBookTag.create!(user_book: user_book, tag: tag) }
        end

        purchase_links.each do |url|
          UserBookPurchaseLink.create!(user_book: user_book, url: url)
        end
      end

      Rails.logger.info "UserBooks::CreateService: user_id=#{current_user.id} isbn=#{isbn} 書籍を本棚に追加しました"
    end

    def self.validate_params!(isbn, content, tags, purchase_links)
      raise ValidationError, "ISBNは13桁の数字で入力してください" unless isbn.to_s.match?(/\A\d{13}\z/)
      raise ValidationError, "contentは#{MAX_CONTENT_LENGTH}文字以内で入力してください" if content && content.length > MAX_CONTENT_LENGTH
      raise ValidationError, "タグは最大#{MAX_TAGS}件まで設定できます" if tags.length > MAX_TAGS
      raise ValidationError, "purchase_linksは最大#{MAX_PURCHASE_LINKS}件まで設定できます" if purchase_links.length > MAX_PURCHASE_LINKS

      purchase_links.each do |url|
        raise ValidationError, "URLの形式が正しくありません" unless url.match?(/\Ahttps?:\/\/.+/i)
        raise ValidationError, "URLは#{MAX_PURCHASE_LINK_LENGTH}文字以内で入力してください" if url.length > MAX_PURCHASE_LINK_LENGTH
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

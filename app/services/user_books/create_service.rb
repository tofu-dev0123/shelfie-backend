module UserBooks
  class CreateService
    def self.call(current_user:, isbn:, content: nil)
      validate_params!(isbn, content)

      book = Book.find_by(isbn: isbn) || fetch_and_create_book!(isbn)

      raise BookAlreadyRegisteredError if UserBook.exists?(user: current_user, book: book)

      UserBook.create!(user: current_user, book: book, content: content)

      Rails.logger.info "UserBooks::CreateService: user_id=#{current_user.id} isbn=#{isbn} 書籍を本棚に追加しました"
    end

    def self.validate_params!(isbn, content)
      raise ValidationError, I18n.t("user_books.errors.isbn_invalid") unless isbn.to_s.match?(BookConstants::ISBN_FORMAT)
      raise ValidationError, I18n.t("user_books.errors.content_too_long", count: UserBookConstants::MAX_CONTENT_LENGTH) if content && content.length > UserBookConstants::MAX_CONTENT_LENGTH
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

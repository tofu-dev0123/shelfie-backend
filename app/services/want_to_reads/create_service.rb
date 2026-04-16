module WantToReads
  class CreateService
    def self.call(current_user:, isbn:)
      validate_isbn!(isbn)

      book = Book.find_by(isbn: isbn) || fetch_and_create_book!(isbn)

      ActiveRecord::Base.transaction do
        WantToRead.create!(user: current_user, book: book)
      rescue ActiveRecord::RecordNotUnique
        raise WantToReadAlreadyExistsError
      end

      Rails.logger.info "WantToReads::CreateService: user_id=#{current_user.id} isbn=#{isbn} 読みたいリストに追加しました"
    end

    def self.validate_isbn!(isbn)
      raise ValidationError, I18n.t("want_to_reads.errors.isbn_invalid") unless isbn.to_s.match?(BookConstants::ISBN_FORMAT)
    end
    private_class_method :validate_isbn!

    # UserBooks::CreateService にも同じメソッドが存在するが、
    # Service 間の依存を避けるため重複を許容している
    def self.fetch_and_create_book!(isbn)
      Rails.logger.info "WantToReads::CreateService: isbn=#{isbn} 楽天書籍APIから取得します"
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

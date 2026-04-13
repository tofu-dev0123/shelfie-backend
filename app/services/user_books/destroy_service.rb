module UserBooks
  class DestroyService
    def self.call(current_user:, isbn:)
      validate_params!(isbn)

      book = Book.find_by(isbn: isbn)
      return unless book

      user_book = UserBook.find_by(user: current_user, book: book)
      return unless user_book

      user_book.destroy!

      Rails.logger.info "UserBooks::DestroyService: user_id=#{current_user.id} isbn=#{isbn} 書籍を本棚から削除しました"
    end

    def self.validate_params!(isbn)
      raise ValidationError, Messages::UserBooks::ISBN_INVALID unless isbn.to_s.match?(/\A\d{13}\z/)
    end
    private_class_method :validate_params!
  end
end

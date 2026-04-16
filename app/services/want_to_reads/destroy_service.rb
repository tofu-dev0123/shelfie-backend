module WantToReads
  class DestroyService
    def self.call(current_user:, isbn:)
      validate_isbn!(isbn)

      # book・want_to_read が存在しない場合も正常終了する（冪等性：削除済みと同じ状態のため）
      book = Book.find_by(isbn: isbn)
      return unless book

      want_to_read = WantToRead.find_by(user: current_user, book: book)
      return unless want_to_read

      want_to_read.destroy!
      Rails.logger.info "WantToReads::DestroyService: user_id=#{current_user.id} isbn=#{isbn} 読みたいリストから削除しました"
    end

    # WantToReads::CreateService にも同じメソッドが存在するが、
    # Service 間の依存を避けるため重複を許容している
    def self.validate_isbn!(isbn)
      raise ValidationError, I18n.t("want_to_reads.errors.isbn_invalid") unless isbn.to_s.match?(/\A\d{13}\z/)
    end
    private_class_method :validate_isbn!
  end
end

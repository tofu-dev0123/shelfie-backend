module UserBooks
  class ShowService
    def self.call(username:, google_books_id:)
      user = User.find_by(username: username)
      raise UserNotFoundError unless user

      user_book = user.user_books
        .includes(:book, :tags, :user_book_purchase_links)
        .joins(:book)
        .find_by(books: { google_books_id: google_books_id })
      raise RecordNotFoundError unless user_book

      Rails.logger.info "UserBooks::ShowService: username=#{username}, google_books_id=#{google_books_id} の投稿詳細を取得しました"

      { user_book: user_book, user: user }
    end
  end
end

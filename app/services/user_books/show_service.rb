module UserBooks
  class ShowService
    def self.call(username:, isbn:, current_user: nil)
      user = User.find_by(username: username)
      raise UserNotFoundError unless user

      user_book = user.user_books
        .includes(:book, :tags, :user_book_purchase_links)
        .joins(:book)
        .find_by(books: { isbn: isbn })
      raise RecordNotFoundError unless user_book

      want_to_read_isbns = Queries::WantToReadIsbnSetQuery.call(user: current_user, isbns: [ user_book.book.isbn ])

      Rails.logger.info "UserBooks::ShowService: username=#{username}, isbn=#{isbn} の投稿詳細を取得しました"

      { user_book: user_book, user: user, want_to_read_isbns: want_to_read_isbns }
    end
  end
end

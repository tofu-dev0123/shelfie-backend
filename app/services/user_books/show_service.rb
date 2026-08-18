module UserBooks
  class ShowService
    def self.call(username:, isbn:)
      user = User.find_by(username: username)
      raise UserNotFoundError unless user

      user_book = user.user_books
        .includes(:book)
        .joins(:book)
        .find_by(books: { isbn: isbn })
      raise RecordNotFoundError unless user_book

      Rails.logger.info "UserBooks::ShowService: username=#{username}, isbn=#{isbn} の投稿詳細を取得しました"

      { user_book: user_book, user: user }
    end
  end
end

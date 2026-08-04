module Users
  class ShowService
    def self.call(username:, current_user: nil)
      user = User.find_by(username: username)
      raise UserNotFoundError unless user

      books_count = user.user_books.count
      links       = user.user_links.pluck(:url)

      Rails.logger.info "Users::ShowService: username=#{username} を取得しました"

      {
        user: user,
        books_count: books_count,
        links: links
      }
    end
  end
end

module Users
  class ShowService
    def self.call(username:, current_user: nil)
      user = User.find_by(username: username)
      raise UserNotFoundError unless user

      followers_count = user.follows_as_followee.count
      following_count = user.follows_as_follower.count
      books_count     = user.user_books.count
      links           = user.user_links.pluck(:url)

      Rails.logger.info "Users::ShowService: username=#{username} を取得しました"

      {
        user: user,
        followers_count: followers_count,
        following_count: following_count,
        books_count: books_count,
        links: links
      }
    end
  end
end

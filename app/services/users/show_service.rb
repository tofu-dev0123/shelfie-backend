module Users
  class ShowService
    def self.call(username:, current_user: nil)
      user = User.find_by(username: username)
      raise UserNotFoundError unless user

      followers_count = user.follows_as_followee.count
      following_count = user.follows_as_follower.count
      books_count     = user.user_books.count
      links           = user.user_links.pluck(:url)

      # 認証済みの場合のみ is_following / is_me を返す。自分自身の場合 is_following は false
      is_following =
        if current_user
          current_user.id == user.id ? false : user.follows_as_followee.exists?(follower_id: current_user.id)
        end

      is_me =
        if current_user
          current_user.id == user.id
        end

      Rails.logger.info "Users::ShowService: username=#{username} を取得しました"

      {
        user: user,
        followers_count: followers_count,
        following_count: following_count,
        books_count: books_count,
        links: links,
        is_following: is_following,
        is_me: is_me
      }
    end
  end
end

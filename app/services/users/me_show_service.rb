module Users
  class MeShowService
    def self.call(current_user:)
      followers_count = current_user.follows_as_followee.count
      following_count = current_user.follows_as_follower.count
      books_count     = current_user.user_books.count
      links           = current_user.user_links.pluck(:url)

      Rails.logger.info "Users::MeShowService: user_id=#{current_user.id} を取得しました"

      {
        user:            current_user,
        followers_count: followers_count,
        following_count: following_count,
        books_count:     books_count,
        links:           links
      }
    end
  end
end

module Queries
  class FollowingQuery
    def self.call(follower_id:, after_id: nil, limit: 20)
      scope = User
        .joins("INNER JOIN follows ON follows.followee_id = users.id")
        .where(follows: { follower_id: follower_id })
        .select("users.*, follows.id AS follow_id")
        .order("follows.id DESC")

      scope = scope.where("follows.id < ?", after_id) if after_id
      scope.limit(limit + 1)
    end
  end
end

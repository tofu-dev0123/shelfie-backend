module Queries
  class FollowersQuery
    def self.call(followee_id:, after_id: nil, limit: 20)
      scope = User
        .joins("INNER JOIN follows ON follows.follower_id = users.id")
        .where(follows: { followee_id: followee_id })
        .select("users.*, follows.id AS follow_id")
        .order("follows.id DESC")

      scope = scope.where("follows.id < ?", after_id) if after_id
      scope.limit(limit + 1)
    end
  end
end

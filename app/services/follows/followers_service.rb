module Follows
  class FollowersService
    def self.call(username:, cursor: nil, limit: nil)
      limit = clamp_limit(limit.to_i)
      after_id = IdCursor.decode(cursor)

      # フォロー系一覧 API は一覧系 API の仕様統一のため、対象ユーザーが存在しない場合も 404 ではなく空配列で 200 を返す
      target = User.find_by(username: username)
      return empty_result unless target

      users = Queries::FollowersQuery.call(
        followee_id: target.id,
        after_id: after_id,
        limit: limit
      )

      has_next = users.size > limit
      users = users.first(limit)
      next_cursor = has_next ? IdCursor.encode(users.last.follow_id) : nil

      Rails.logger.info "Follows::FollowersService: username=#{username} のフォロワー一覧を取得しました"

      {
        items: users.map { |u| UserSummarySerializer.new(u).as_json },
        pagination: {
          next_cursor: next_cursor,
          has_next:    has_next
        }
      }
    end

    def self.clamp_limit(limit)
      return FollowConstants::DEFAULT_LIMIT if limit <= 0

      [ limit, FollowConstants::MAX_LIMIT ].min
    end
    private_class_method :clamp_limit

    def self.empty_result
      {
        items: [],
        pagination: {
          next_cursor: nil,
          has_next:    false
        }
      }
    end
    private_class_method :empty_result
  end
end

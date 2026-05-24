module Feed
  class IndexService
    def self.call(current_user: nil, cursor: nil, limit: nil)
      limit = clamp_limit(limit.to_i)
      after_id = IdCursor.decode(cursor)
      user_ids = target_user_ids(current_user)

      user_books = Queries::FeedQuery.call(user_ids: user_ids, after_id: after_id, limit: limit)

      has_next = user_books.size > limit
      user_books = user_books.first(limit)
      next_cursor = has_next ? IdCursor.encode(user_books.last.id) : nil

      want_to_read_isbns = Queries::WantToReadIsbnSetQuery.call(
        user: current_user,
        isbns: user_books.map { |ub| ub.book.isbn }
      )

      Rails.logger.info "Feed::IndexService: current_user_id=#{current_user&.id} のフィードを取得しました"

      {
        items: user_books.map { |ub| FeedItemSerializer.new(ub, want_to_read_isbns: want_to_read_isbns).as_json },
        pagination: {
          next_cursor: next_cursor,
          has_next: has_next
        }
      }
    end

    def self.clamp_limit(limit)
      return FeedConstants::DEFAULT_LIMIT if limit <= 0

      [ limit, FeedConstants::MAX_LIMIT ].min
    end

    def self.target_user_ids(current_user)
      return nil unless current_user

      followee_ids = current_user.follows_as_follower.pluck(:followee_id)
      [ current_user.id, *followee_ids ]
    end

    private_class_method :clamp_limit, :target_user_ids
  end
end

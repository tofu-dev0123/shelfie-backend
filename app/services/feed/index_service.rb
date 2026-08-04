module Feed
  class IndexService
    def self.call(current_user: nil, cursor: nil, limit: nil)
      limit = clamp_limit(limit.to_i)
      after = CompoundCursor.decode(cursor)

      user_books = Queries::FeedQuery.call(cursor: after, limit: limit)

      has_next = user_books.size > limit
      user_books = user_books.first(limit)
      next_cursor = has_next ? CompoundCursor.encode(created_at: user_books.last.created_at, id: user_books.last.id) : nil

      Rails.logger.info "Feed::IndexService: current_user_id=#{current_user&.id} のフィードを取得しました"

      {
        items: user_books.map { |ub| FeedItemSerializer.new(ub).as_json },
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

    private_class_method :clamp_limit
  end
end

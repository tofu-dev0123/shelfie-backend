module Queries
  class FeedQuery
    def self.call(user_ids: nil, cursor: nil, limit: FeedConstants::DEFAULT_LIMIT)
      scope = UserBook
        .includes(:book, :user)
        .order(created_at: :desc, id: :desc)

      scope = scope.where(user_id: user_ids) if user_ids
      scope = CompoundCursor.apply_to(scope, table: "user_books", cursor: cursor)
      scope.limit(limit + 1)
    end
  end
end

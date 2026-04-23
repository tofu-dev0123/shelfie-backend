module Queries
  class FeedQuery
    def self.call(user_ids: nil, after_id: nil, limit: FeedConstants::DEFAULT_LIMIT)
      scope = UserBook
        .includes(:book, :user, :tags)
        .order(created_at: :desc, id: :desc)

      scope = scope.where(user_id: user_ids) if user_ids
      scope = scope.where("user_books.id < ?", after_id) if after_id
      scope.limit(limit + 1)
    end
  end
end

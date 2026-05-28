module Queries
  class PostSearchQuery
    def self.call(q: nil, tag: nil, cursor: nil, limit: PostConstants::DEFAULT_LIMIT)
      scope = UserBook
        .includes(:book, :user, :tags)
        .order(created_at: :desc, id: :desc)

      if q.present?
        sanitized = ActiveRecord::Base.sanitize_sql_like(q)
        scope = scope.where("user_books.content ILIKE ?", "%#{sanitized}%")
      elsif tag.present?
        scope = scope.joins(:tags).where(tags: { name: tag })
      end

      scope = CompoundCursor.apply_to(scope, table: "user_books", cursor: cursor)
      scope.limit(limit + 1)
    end
  end
end

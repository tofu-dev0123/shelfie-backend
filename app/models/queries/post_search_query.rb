module Queries
  class PostSearchQuery
    def self.call(q: nil, tag: nil, after_id: nil, limit: PostConstants::DEFAULT_LIMIT)
      scope = UserBook
        .includes(:book, :user, :tags)
        .order(created_at: :desc, id: :desc)

      if q.present?
        sanitized = ActiveRecord::Base.sanitize_sql_like(q)
        scope = scope.where("user_books.content ILIKE ?", "%#{sanitized}%")
      elsif tag.present?
        scope = scope.joins(:tags).where(tags: { name: tag })
      end

      scope = scope.where("user_books.id < ?", after_id) if after_id
      scope.limit(limit + 1)
    end
  end
end

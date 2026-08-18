module UserBooks
  class IndexService
    def self.call(username:, cursor: nil, limit: nil)
      user = User.find_by(username: username)
      raise UserNotFoundError unless user

      limit = clamp_limit(limit.to_i)
      after = CompoundCursor.decode(cursor)

      scope = user.user_books
        .includes(:book)
        .order(created_at: :desc, id: :desc)
      user_books = CompoundCursor.apply_to(scope, table: "user_books", cursor: after)
        .limit(limit + 1)

      has_next = user_books.size > limit
      user_books = user_books.first(limit)
      next_cursor = has_next ? CompoundCursor.encode(created_at: user_books.last.created_at, id: user_books.last.id) : nil

      Rails.logger.info "UserBooks::IndexService: username=#{username} の本棚を取得しました"

      {
        items: user_books.map { |ub| UserBookSerializer.new(ub).as_json },
        pagination: {
          next_cursor: next_cursor,
          has_next: has_next
        }
      }
    end

    def self.clamp_limit(limit)
      return UserBookConstants::DEFAULT_LIMIT if limit <= 0

      [ limit, UserBookConstants::MAX_LIMIT ].min
    end

    private_class_method :clamp_limit
  end
end

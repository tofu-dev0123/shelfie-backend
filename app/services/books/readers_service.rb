module Books
  class ReadersService
    def self.call(isbn:, cursor: nil, limit: nil)
      limit = clamp_limit(limit.to_i)
      after_id = decode_cursor(cursor)

      users = Queries::BookReadersQuery.call(
        isbn: isbn,
        after_id: after_id,
        limit: limit
      )

      has_next = users.size > limit
      users = users.first(limit)
      next_cursor = has_next ? encode_cursor(users.last.user_book_id) : nil

      {
        items: users.map { |user| UserSummarySerializer.new(user).as_json },
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

    def self.decode_cursor(cursor)
      return nil if cursor.blank?

      decoded = JSON.parse(Base64.strict_decode64(cursor))
      id = decoded["id"]
      raise ValidationError, "invalid cursor" unless id.is_a?(Integer) && id >= 0

      id
    rescue ArgumentError, JSON::ParserError
      raise ValidationError, "invalid cursor"
    end

    def self.encode_cursor(user_book_id)
      Base64.strict_encode64({ id: user_book_id }.to_json)
    end

    private_class_method :clamp_limit, :decode_cursor, :encode_cursor
  end
end

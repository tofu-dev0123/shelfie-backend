module UserBooks
  class IndexService
    def self.call(username:, cursor: nil, limit: nil)
      user = User.find_by(username: username)
      raise UserNotFoundError unless user

      limit = clamp_limit(limit.to_i)
      after_id = decode_cursor(cursor)

      user_books = user.user_books
        .includes(:book, :tags)
        .order(created_at: :desc, id: :desc)
        .then { |scope| after_id ? scope.where("user_books.id < ?", after_id) : scope }
        .limit(limit + 1)

      has_next = user_books.size > limit
      user_books = user_books.first(limit)
      next_cursor = has_next ? encode_cursor(user_books.last.id) : nil

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

    def self.decode_cursor(cursor)
      return nil if cursor.blank?

      decoded = JSON.parse(Base64.strict_decode64(cursor))
      id = decoded["id"]
      raise ValidationError, "invalid cursor" unless id.is_a?(Integer) && id >= 0

      id
    rescue ArgumentError, JSON::ParserError
      raise ValidationError, "invalid cursor"
    end

    def self.encode_cursor(id)
      Base64.strict_encode64({ id: id }.to_json)
    end

    private_class_method :clamp_limit, :decode_cursor, :encode_cursor
  end
end

module Posts
  class SearchService
    def self.call(q: nil, tag: nil, current_user: nil, cursor: nil, limit: nil)
      q   = q.to_s.strip
      tag = tag.to_s.strip

      validate_params!(q, tag)

      limit  = clamp_limit(limit.to_i)
      after  = CompoundCursor.decode(cursor)

      user_books = Queries::PostSearchQuery.call(
        q: q.presence,
        tag: tag.presence,
        cursor: after,
        limit: limit
      )

      has_next    = user_books.size > limit
      user_books  = user_books.first(limit)
      next_cursor = has_next ? CompoundCursor.encode(created_at: user_books.last.created_at, id: user_books.last.id) : nil

      want_to_read_isbns = Queries::WantToReadIsbnSetQuery.call(
        user: current_user,
        isbns: user_books.map { |ub| ub.book.isbn }
      )

      Rails.logger.info "Posts::SearchService: q=#{q.presence.inspect} tag=#{tag.presence.inspect} 件数=#{user_books.size} has_next=#{has_next}"

      {
        items: user_books.map { |ub| FeedItemSerializer.new(ub, want_to_read_isbns: want_to_read_isbns).as_json },
        pagination: {
          next_cursor: next_cursor,
          has_next: has_next
        }
      }
    end

    def self.validate_params!(q, tag)
      raise ValidationError, "q または tag のいずれかを指定してください" if q.blank? && tag.blank?
      raise ValidationError, "q と tag は同時に指定できません" if q.present? && tag.present?
      raise ValidationError, "q が長すぎます"   if q.present?   && q.length > PostConstants::MAX_QUERY_LENGTH
      raise ValidationError, "tag が長すぎます" if tag.present? && tag.length > TagConstants::MAX_QUERY_LENGTH
    end

    def self.clamp_limit(limit)
      return PostConstants::DEFAULT_LIMIT if limit <= 0

      [ limit, PostConstants::MAX_LIMIT ].min
    end

    private_class_method :validate_params!, :clamp_limit
  end
end

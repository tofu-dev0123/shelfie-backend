module WantToReads
  class IndexService
    def self.call(current_user:, cursor: nil, limit: nil)
      limit = clamp_limit(limit.to_i)
      after = CompoundCursor.decode(cursor)

      scope = current_user.want_to_reads
        .includes(:book)
        .order(created_at: :desc, id: :desc)
      want_to_reads = CompoundCursor.apply_to(scope, table: "want_to_reads", cursor: after)
        .limit(limit + 1)

      has_next      = want_to_reads.size > limit
      want_to_reads = want_to_reads.first(limit)
      next_cursor   = has_next ? CompoundCursor.encode(created_at: want_to_reads.last.created_at, id: want_to_reads.last.id) : nil

      Rails.logger.info "WantToReads::IndexService: user_id=#{current_user.id} の読みたいリストを取得しました"

      {
        items: want_to_reads.map { |wtr| WantToReadSerializer.new(wtr).as_json },
        pagination: {
          next_cursor: next_cursor,
          has_next:    has_next
        }
      }
    end

    def self.clamp_limit(limit)
      return WantToReadConstants::DEFAULT_LIMIT if limit <= 0

      [ limit, WantToReadConstants::MAX_LIMIT ].min
    end

    private_class_method :clamp_limit
  end
end

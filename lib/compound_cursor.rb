class CompoundCursor
  def self.encode(created_at:, id:)
    Base64.strict_encode64({ created_at: created_at.iso8601(6), id: id }.to_json)
  end

  def self.decode(cursor)
    return nil if cursor.blank?

    decoded = JSON.parse(Base64.strict_decode64(cursor))
    id = decoded["id"]
    raise ValidationError, "invalid cursor" unless id.is_a?(Integer) && id >= 0

    created_at_str = decoded["created_at"]
    created_at = nil
    if created_at_str
      raise ValidationError, "invalid cursor" unless created_at_str.is_a?(String)

      created_at = Time.iso8601(created_at_str)
    end

    { created_at: created_at, id: id }
  rescue ArgumentError, JSON::ParserError
    raise ValidationError, "invalid cursor"
  end

  # PostgreSQL の Tuple 比較で (created_at, id) の境界フィルタを scope に適用する。
  # 旧形式カーソル（created_at が nil）の場合は id 単独比較にフォールバックする。
  def self.apply_to(scope, table:, cursor:)
    return scope unless cursor

    quoted_table = ActiveRecord::Base.connection.quote_table_name(table)
    if cursor[:created_at]
      scope.where(
        "(#{quoted_table}.created_at, #{quoted_table}.id) < (?, ?)",
        cursor[:created_at],
        cursor[:id]
      )
    else
      scope.where("#{quoted_table}.id < ?", cursor[:id])
    end
  end
end

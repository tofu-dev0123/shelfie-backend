class IdCursor
  def self.encode(id)
    Base64.strict_encode64({ id: id }.to_json)
  end

  def self.decode(cursor)
    return nil if cursor.blank?

    decoded = JSON.parse(Base64.strict_decode64(cursor))
    id = decoded["id"]
    raise ValidationError, "invalid cursor" unless id.is_a?(Integer) && id >= 0

    id
  rescue ArgumentError, JSON::ParserError
    raise ValidationError, "invalid cursor"
  end
end

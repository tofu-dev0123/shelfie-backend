class Cursor
  def self.encode(start_index)
    Base64.strict_encode64({ startIndex: start_index }.to_json)
  end

  def self.decode(cursor)
    return 0 if cursor.blank?

    decoded = JSON.parse(Base64.strict_decode64(cursor))
    start_index = decoded["startIndex"]
    raise ValidationError, "invalid cursor" unless start_index.is_a?(Integer) && start_index >= 0

    start_index
  rescue ArgumentError, JSON::ParserError
    raise ValidationError, "invalid cursor"
  end
end

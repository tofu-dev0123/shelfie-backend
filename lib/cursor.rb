class Cursor
  def self.encode(page)
    Base64.strict_encode64({ page: page }.to_json)
  end

  def self.decode(cursor)
    return 1 if cursor.blank?

    decoded = JSON.parse(Base64.strict_decode64(cursor))
    page = decoded["page"]
    raise ValidationError, "invalid cursor" unless page.is_a?(Integer) && page >= 1

    page
  rescue ArgumentError, JSON::ParserError
    raise ValidationError, "invalid cursor"
  end
end

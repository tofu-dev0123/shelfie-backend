module Books
  class SearchService
    MAX_QUERY_LENGTH = 100
    EXPECTED_PAGE_SIZE = GoogleBooksClient::MAX_RESULTS

    def self.call(q:, cursor: nil)
      q = q.to_s.strip
      raise ValidationError, "q is blank" if q.blank?
      raise ValidationError, "q is too long" if q.length > MAX_QUERY_LENGTH

      start_index = Cursor.decode(cursor)

      result = GoogleBooksClient.call(q: q, start_index: start_index)
      items = parse_items(result[:items] || [])
      has_next = items.size >= EXPECTED_PAGE_SIZE
      next_cursor = has_next ? Cursor.encode(start_index + items.size) : nil

      Rails.logger.info "Books::SearchService: q=#{q} start_index=#{start_index} 件数=#{items.size} has_next=#{has_next}"

      {
        items: items,
        pagination: {
          next_cursor: next_cursor,
          has_next: has_next
        }
      }
    end

    def self.parse_items(raw_items)
      raw_items.map do |item|
        info = item[:volumeInfo] || {}
        {
          google_books_id: item[:id],
          title: info[:title],
          authors: info[:authors] || [],
          thumbnail_url: info.dig(:imageLinks, :thumbnail)
        }
      end
    end
    private_class_method :parse_items
  end
end

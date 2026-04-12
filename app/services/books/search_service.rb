module Books
  class SearchService
    def self.call(q:, cursor: nil)
      q = q.to_s.strip
      raise ValidationError, "q is blank" if q.blank?
      raise ValidationError, "q is too long" if q.length > BookConstants::MAX_QUERY_LENGTH

      page   = Cursor.decode(cursor)
      result = RakutenBooksClient.call(q: q, page: page)
      items  = parse_items(result[:Items] || [])

      has_next    = page < (result[:pageCount] || 0)
      next_cursor = has_next ? Cursor.encode(page + 1) : nil

      Rails.logger.info "Books::SearchService: q=#{q} page=#{page} 件数=#{items.size} has_next=#{has_next}"

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
        {
          isbn:          item[:isbn],
          title:         item[:title],
          authors:       item[:author]&.split("／") || [],
          thumbnail_url: item[:largeImageUrl]
        }
      end
    end
    private_class_method :parse_items
  end
end

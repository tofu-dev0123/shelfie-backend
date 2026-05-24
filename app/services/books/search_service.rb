module Books
  class SearchService
    def self.call(q:, cursor: nil, current_user: nil)
      q = q.to_s.strip
      raise ValidationError, "q is blank" if q.blank?
      raise ValidationError, "q is too long" if q.length > BookConstants::MAX_QUERY_LENGTH

      page   = Cursor.decode(cursor)
      result = RakutenBooksClient.call(q: q, page: page)
      raw_items = result[:Items] || []
      want_to_read_isbns = Queries::WantToReadIsbnSetQuery.call(
        user: current_user,
        isbns: raw_items.map { |item| item[:isbn] }
      )
      items = parse_items(raw_items, want_to_read_isbns)

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

    def self.parse_items(raw_items, want_to_read_isbns)
      raw_items.map do |item|
        {
          isbn:                  item[:isbn],
          title:                 item[:title],
          authors:               item[:author]&.split("／") || [],
          thumbnail_url:         item[:largeImageUrl],
          is_in_my_want_to_read: want_to_read_isbns.nil? ? nil : want_to_read_isbns.include?(item[:isbn])
        }
      end
    end
    private_class_method :parse_items
  end
end

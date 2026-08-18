module Books
  class ShowService
    def self.call(isbn:)
      isbn = isbn.to_s.strip
      raise ValidationError, "isbn is blank" if isbn.blank?
      raise ValidationError, "isbn is invalid" unless isbn.match?(BookConstants::ISBN_FORMAT)

      result   = RakutenBooksClient.find_by_isbn(isbn: isbn)
      raw_item = (result[:Items] || []).first
      raise RecordNotFoundError, "book not found: #{isbn}" if raw_item.nil?

      Rails.logger.info "Books::ShowService: isbn=#{isbn} found=true"

      parse_item(raw_item)
    end

    def self.parse_item(item)
      {
        isbn:          item[:isbn],
        title:         item[:title],
        authors:       item[:author]&.split("／") || [],
        thumbnail_url: item[:largeImageUrl]
      }
    end
    private_class_method :parse_item
  end
end

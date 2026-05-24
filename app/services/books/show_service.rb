module Books
  class ShowService
    def self.call(isbn:, current_user: nil)
      isbn = isbn.to_s.strip
      raise ValidationError, "isbn is blank" if isbn.blank?
      raise ValidationError, "isbn is invalid" unless isbn.match?(BookConstants::ISBN_FORMAT)

      result   = RakutenBooksClient.find_by_isbn(isbn: isbn)
      raw_item = (result[:Items] || []).first
      raise RecordNotFoundError, "book not found: #{isbn}" if raw_item.nil?

      want_to_read_isbns = Queries::WantToReadIsbnSetQuery.call(user: current_user, isbns: [ raw_item[:isbn] ])

      Rails.logger.info "Books::ShowService: isbn=#{isbn} found=true"

      parse_item(raw_item, want_to_read_isbns)
    end

    # want_to_read_isbns が nil（未ログイン）なら is_in_my_want_to_read も nil を返す。
    def self.parse_item(item, want_to_read_isbns)
      {
        isbn:                  item[:isbn],
        title:                 item[:title],
        authors:               item[:author]&.split("／") || [],
        thumbnail_url:         item[:largeImageUrl],
        is_in_my_want_to_read: want_to_read_isbns.nil? ? nil : want_to_read_isbns.include?(item[:isbn])
      }
    end
    private_class_method :parse_item
  end
end

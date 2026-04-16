class WantToReadSerializer
  def initialize(want_to_read)
    @want_to_read = want_to_read
  end

  def as_json
    {
      isbn:          @want_to_read.book.isbn,
      title:         @want_to_read.book.title,
      authors:       @want_to_read.book.authors,
      thumbnail_url: @want_to_read.book.thumbnail_url
    }
  end
end

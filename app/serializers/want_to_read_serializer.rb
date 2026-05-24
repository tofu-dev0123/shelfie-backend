class WantToReadSerializer
  def initialize(want_to_read)
    @want_to_read = want_to_read
  end

  def as_json
    {
      isbn:                  @want_to_read.book.isbn,
      title:                 @want_to_read.book.title,
      authors:               @want_to_read.book.authors,
      thumbnail_url:         @want_to_read.book.thumbnail_url,
      # 自分の読みたいリスト由来なので常に true。Book レスポンスのインターフェイスを統一する目的で含める
      is_in_my_want_to_read: true
    }
  end
end

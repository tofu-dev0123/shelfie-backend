class FeedItemSerializer
  # want_to_read_isbns: 認証ユーザーの読みたい登録済み ISBN の Set。未ログイン時は nil。
  def initialize(user_book, want_to_read_isbns: nil)
    @user_book = user_book
    @want_to_read_isbns = want_to_read_isbns
  end

  def as_json
    {
      id:         @user_book.id,
      content:    @user_book.content,
      tags:       @user_book.tags.sort_by(&:name).map(&:name),
      created_at: @user_book.created_at.iso8601,
      book: {
        isbn:                  @user_book.book.isbn,
        title:                 @user_book.book.title,
        authors:               @user_book.book.authors,
        thumbnail_url:         @user_book.book.thumbnail_url,
        is_in_my_want_to_read: is_in_my_want_to_read
      },
      user: UserSummarySerializer.new(@user_book.user).as_json
    }
  end

  private

  # 未ログイン時は nil（判定不能）、ログイン時は Set の include? で boolean を返す。
  def is_in_my_want_to_read
    return nil if @want_to_read_isbns.nil?

    @want_to_read_isbns.include?(@user_book.book.isbn)
  end
end

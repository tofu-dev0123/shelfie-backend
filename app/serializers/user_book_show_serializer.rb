class UserBookShowSerializer
  def initialize(user_book, user)
    @user_book = user_book
    @user = user
  end

  def as_json
    {
      id: @user_book.id,
      content: @user_book.content,
      tags: @user_book.tags.map(&:name),
      created_at: @user_book.created_at.iso8601,
      updated_at: @user_book.updated_at.iso8601,
      book: {
        isbn: @user_book.book.isbn,
        title: @user_book.book.title,
        authors: @user_book.book.authors,
        thumbnail_url: @user_book.book.thumbnail_url
      },
      user: {
        username: @user.username,
        nickname: @user.nickname,
        avatar_url: avatar_url
      },
      purchase_links: @user_book.user_book_purchase_links.map(&:url)
    }
  end

  private

  def avatar_url
    return nil if @user.avatar_key.nil?

    "https://#{CdnConstants::CLOUDFRONT_HOST}/#{@user.avatar_key}"
  end
end

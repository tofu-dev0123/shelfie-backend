class UserBookSerializer
  def initialize(user_book)
    @user_book = user_book
  end

  def as_json
    {
      id: @user_book.id,
      content: @user_book.content,
      tags: @user_book.tags.map(&:name),
      created_at: @user_book.created_at.iso8601,
      book: {
        isbn: @user_book.book.isbn,
        title: @user_book.book.title,
        authors: @user_book.book.authors,
        thumbnail_url: @user_book.book.thumbnail_url
      }
    }
  end
end

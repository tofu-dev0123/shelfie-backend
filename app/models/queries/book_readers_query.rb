module Queries
  class BookReadersQuery
    def self.call(google_books_id:, after_id: nil, limit: 20)
      scope = User
        .joins(user_books: :book)
        .where(books: { google_books_id: google_books_id })
        .select("users.*, user_books.id AS user_book_id")
        .order("user_books.id ASC")

      scope = scope.where("user_books.id > ?", after_id) if after_id
      scope.limit(limit + 1)
    end
  end
end

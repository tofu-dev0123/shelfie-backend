module Queries
  class BookReadersQuery
    def self.call(isbn:, after_id: nil, limit: 20)
      scope = User
        .joins(user_books: :book)
        .where(books: { isbn: isbn })
        .select("users.*, user_books.id AS user_book_id")
        .order("user_books.id ASC")

      scope = scope.where("user_books.id > ?", after_id) if after_id
      scope.limit(limit + 1)
    end
  end
end

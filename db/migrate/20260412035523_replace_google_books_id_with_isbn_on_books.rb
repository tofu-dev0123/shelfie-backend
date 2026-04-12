class ReplaceGoogleBooksIdWithIsbnOnBooks < ActiveRecord::Migration[8.1]
  def change
    remove_index  :books, :google_books_id
    remove_column :books, :isbn
    rename_column :books, :google_books_id, :isbn
    change_column :books, :isbn, :string, limit: 13, null: false
    add_index     :books, :isbn, unique: true, name: "index_books_on_isbn"
  end
end

class RemoveStatusFromUserBooks < ActiveRecord::Migration[8.1]
  def change
    remove_column :user_books, :status, :enum
    drop_enum :user_book_status
  end
end

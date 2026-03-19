class RenameLikesToWantToReads < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :likes, :user_books
    remove_foreign_key :likes, :users

    remove_index :likes, [ :user_id, :user_book_id ]
    remove_index :likes, :user_book_id
    remove_index :likes, :user_id

    rename_table :likes, :want_to_reads

    remove_column :want_to_reads, :user_book_id, :bigint

    add_reference :want_to_reads, :book, null: false, foreign_key: { on_delete: :restrict }, index: false

    add_index :want_to_reads, [ :user_id, :book_id ], unique: true
    add_index :want_to_reads, :user_id
    add_index :want_to_reads, :book_id

    add_foreign_key :want_to_reads, :users, on_delete: :restrict
  end
end

class CreateUserBooks < ActiveRecord::Migration[8.1]
  def change
    create_enum :user_book_status, %w[want_to_read reading completed]

    create_table :user_books do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.references :book, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.enum :status, enum_type: :user_book_status, null: false
      t.text :content
      t.timestamps
    end

    add_index :user_books, [ :user_id, :book_id ], unique: true
    add_index :user_books, [ :user_id, :created_at ], order: { created_at: :desc }
    add_index :user_books, :book_id
  end
end

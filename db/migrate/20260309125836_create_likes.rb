class CreateLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.references :user_book, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.datetime :created_at, null: false
    end

    add_index :likes, [ :user_id, :user_book_id ], unique: true
    add_index :likes, :user_id
    add_index :likes, :user_book_id
  end
end

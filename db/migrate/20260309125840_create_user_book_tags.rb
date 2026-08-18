class CreateUserBookTags < ActiveRecord::Migration[8.1]
  def change
    create_table :user_book_tags do |t|
      t.references :user_book, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.references :tag, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.datetime :created_at, null: false
    end

    add_index :user_book_tags, [ :user_book_id, :tag_id ], unique: true
    add_index :user_book_tags, :tag_id
  end
end

class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :google_books_id, limit: 50, null: false
      t.string :title, limit: 255, null: false
      t.string :authors, limit: 255, array: true, null: false, default: []
      t.string :isbn, limit: 17
      t.string :thumbnail_url, limit: 2048
      t.string :published_date, limit: 10
      t.timestamps
    end

    add_index :books, :google_books_id, unique: true
  end
end

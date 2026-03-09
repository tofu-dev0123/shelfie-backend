class CreateUserBookPurchaseLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :user_book_purchase_links do |t|
      t.references :user_book, null: false, foreign_key: { on_delete: :restrict }
      t.string :url, limit: 2048, null: false
      t.timestamps
    end
  end
end

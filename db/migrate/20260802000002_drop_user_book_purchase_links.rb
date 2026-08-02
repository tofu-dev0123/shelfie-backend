class DropUserBookPurchaseLinks < ActiveRecord::Migration[8.1]
  # 購入リンク機能の廃止に伴い、user_book_purchase_links テーブルを削除する。
  def up
    drop_table :user_book_purchase_links
  end

  def down
    create_table :user_book_purchase_links do |t|
      t.references :user_book, null: false, foreign_key: { on_delete: :restrict }
      t.string :url, limit: 2048, null: false
      t.timestamps
    end
  end
end

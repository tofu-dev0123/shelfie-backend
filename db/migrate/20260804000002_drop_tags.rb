class DropTags < ActiveRecord::Migration[8.1]
  # タグ機能の廃止に伴い、tags / user_book_tags テーブルを削除する。
  # user_book_tags が tags を参照しているため、先に user_book_tags を削除する。
  # 機能ごと削除するため復元はしない（不可逆）。
  def up
    drop_table :user_book_tags
    drop_table :tags
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

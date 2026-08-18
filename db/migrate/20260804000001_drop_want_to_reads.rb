class DropWantToReads < ActiveRecord::Migration[8.1]
  # 読みたいリスト機能の廃止に伴い、want_to_reads テーブルを削除する。
  # 機能ごと削除するため復元はしない（不可逆）。
  def up
    drop_table :want_to_reads
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

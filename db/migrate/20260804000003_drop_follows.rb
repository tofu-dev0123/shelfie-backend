class DropFollows < ActiveRecord::Migration[8.1]
  # フォロー機能の廃止に伴い、follows テーブルを削除する。
  # users への外部キーと自己フォロー禁止の check 制約もテーブルごと削除される。
  # 機能ごと削除するため復元はしない（不可逆）。
  def up
    drop_table :follows
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

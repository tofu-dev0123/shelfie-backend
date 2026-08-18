class DropTagFollows < ActiveRecord::Migration[8.1]
  # タグ仕様変更（本文中ハッシュタグ＋サジェスト方式）に伴いタグフォロー機能を廃止するため、
  # tag_follows テーブルを削除する。データは 20260419000001 で既に TRUNCATE 済み。
  def up
    drop_table :tag_follows
  end

  def down
    create_table :tag_follows do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.references :tag, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.datetime :created_at, null: false
    end

    add_index :tag_follows, [ :user_id, :tag_id ], unique: true
    add_index :tag_follows, :user_id
  end
end

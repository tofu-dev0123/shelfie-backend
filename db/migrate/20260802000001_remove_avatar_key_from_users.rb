class RemoveAvatarKeyFromUsers < ActiveRecord::Migration[8.1]
  # アバター機能の廃止（S3 / LocalStack 依存の除去）に伴い、users.avatar_key を削除する。
  def up
    remove_column :users, :avatar_key
  end

  def down
    add_column :users, :avatar_key, :string
  end
end

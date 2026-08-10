class RemoveClerkUserIdFromUsers < ActiveRecord::Migration[8.1]
  # 認証の入口が OAuth に切り替わり、外部 ID は user_identities が持つ。
  # ロールバックしてもカラムの中身は戻らないため、型定義のみ復元する。
  def change
    remove_column :users, :clerk_user_id, :string, limit: 50, null: false
  end
end

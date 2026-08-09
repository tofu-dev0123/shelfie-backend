class CreateUserIdentities < ActiveRecord::Migration[8.1]
  # 「同じ人が複数の認証手段を持てる」ことを表現するため、identity を users から切り出す。
  # users.provider / users.provider_uid にすると 1ユーザー = 1プロバイダが構造的に固定される。
  def change
    create_table :user_identities do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }
      t.string :provider, limit: 20, null: false
      # Google の sub は最大255文字
      t.string :provider_uid, limit: 255, null: false
      # プロバイダ側のメール（表示・監査用）。users.email と一致しなくてよい
      t.string :email, limit: 254, null: false
      t.timestamps

      # 同じ外部IDが2ユーザーに紐づかない
      t.index [ :provider, :provider_uid ], unique: true
      # 同一プロバイダの二重連携を防ぐ
      t.index [ :user_id, :provider ], unique: true
    end
  end
end

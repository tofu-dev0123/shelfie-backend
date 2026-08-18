class CreateRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }
      t.string :token, limit: 128, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
    end

    add_index :refresh_tokens, :token, unique: true
    add_index :refresh_tokens, :expires_at
  end
end

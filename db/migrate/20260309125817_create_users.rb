class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :clerk_user_id, limit: 50, null: false
      t.string :email, limit: 254, null: false
      t.string :nickname, limit: 30, null: false
      t.string :username, limit: 40, null: false
      t.string :avatar_url, limit: 2048
      t.text :bio
      t.timestamps
    end

    add_index :users, :clerk_user_id, unique: true
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
  end
end

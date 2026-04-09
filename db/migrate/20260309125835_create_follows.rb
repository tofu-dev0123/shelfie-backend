class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.bigint :follower_id, null: false
      t.bigint :followee_id, null: false
      t.datetime :created_at, null: false
    end

    add_index :follows, [ :follower_id, :followee_id ], unique: true
    add_index :follows, :follower_id
    add_index :follows, :followee_id
    add_foreign_key :follows, :users, column: :follower_id, on_delete: :restrict
    add_foreign_key :follows, :users, column: :followee_id, on_delete: :restrict
    add_check_constraint :follows, "follower_id != followee_id", name: "check_follows_no_self"
  end
end

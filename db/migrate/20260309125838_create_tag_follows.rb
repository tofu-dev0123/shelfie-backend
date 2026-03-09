class CreateTagFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :tag_follows do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.references :tag, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.datetime :created_at, null: false
    end

    add_index :tag_follows, [:user_id, :tag_id], unique: true
    add_index :tag_follows, :user_id
  end
end

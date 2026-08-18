class CreateUserLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :user_links do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }
      t.string :url, limit: 2048, null: false
      t.timestamps
    end
  end
end

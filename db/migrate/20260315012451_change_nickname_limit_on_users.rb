class ChangeNicknameLimitOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column :users, :nickname, :string, limit: 50, null: false
  end
end

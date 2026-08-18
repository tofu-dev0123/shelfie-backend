class RenameAvatarUrlToAvatarKeyInUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :avatar_url, :avatar_key
    change_column :users, :avatar_key, :string, limit: nil
  end
end

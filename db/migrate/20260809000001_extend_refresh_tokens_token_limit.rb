class ExtendRefreshTokensTokenLimit < ActiveRecord::Migration[8.1]
  # JWT の payload に purpose クレームを追加した分だけトークンが伸び、
  # varchar(128) に収まらなくなったため上限を広げる。
  # 512 は今後クレームが数個増えても耐える余裕を見込んだ値。
  def up
    change_column :refresh_tokens, :token, :string, limit: 512, null: false
  end

  def down
    change_column :refresh_tokens, :token, :string, limit: 128, null: false
  end
end

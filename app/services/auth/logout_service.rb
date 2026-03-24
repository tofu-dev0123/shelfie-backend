module Auth
  class LogoutService
    def self.call(refresh_token:)
      # リフレッシュトークンが Cookie にない場合はすでにログアウト済みとみなす
      return :already_logged_out if refresh_token.blank?

      record = RefreshToken.find_by(token: refresh_token)

      # DBにレコードが存在しない場合もすでにログアウト済みとみなす（冪等性）
      return :already_logged_out unless record

      record.destroy

      Rails.logger.info "ログアウト成功: user_id=#{record.user_id}"
      :logged_out
    end
  end
end

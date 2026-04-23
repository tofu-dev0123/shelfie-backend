module Auth
  class LoginService
    def self.call(clerk_token:)
      # ClerkのJWTを検証し、ペイロードからClerkユーザーIDを取得する
      clerk_payload = ClerkClient.verify(clerk_token)

      # Clerk側のユーザーIDをキーにローカルDBのユーザーを特定する
      user = User.find_by(clerk_user_id: clerk_payload[:clerk_user_id])
      unless user
        Rails.logger.warn "ログイン失敗: ユーザーが見つかりません clerk_user_id=#{clerk_payload[:clerk_user_id]}"
        raise UserNotFoundError
      end

      access_token  = TokenIssuer.issue_access_token(user)
      refresh_token = TokenIssuer.issue_refresh_token(user)
      refresh_token_expires_at = TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now

      # リフレッシュトークンはDBで管理し、失効・ローテーションを可能にする
      RefreshToken.create!(
        user: user,
        token: refresh_token,
        expires_at: refresh_token_expires_at
      )

      Rails.logger.info "ログイン成功: user_id=#{user.id}"
      {
        access_token: access_token,
        refresh_token: refresh_token,
        refresh_token_expires_at: refresh_token_expires_at
      }
    end
  end
end

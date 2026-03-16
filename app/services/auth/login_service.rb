module Auth
  class LoginService
    def self.call(clerk_token:)
      clerk_payload = ClerkClient.verify(clerk_token)

      user = User.find_by(clerk_user_id: clerk_payload[:clerk_user_id])
      raise UserNotFoundError unless user

      access_token  = TokenIssuer.issue_access_token(user)
      refresh_token = TokenIssuer.issue_refresh_token(user)

      RefreshToken.create!(
        user: user,
        token: refresh_token,
        expires_at: TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now
      )

      Rails.logger.info "ログイン成功: user_id=#{user.id}"
      { access_token: access_token, refresh_token: refresh_token }
    end
  end
end

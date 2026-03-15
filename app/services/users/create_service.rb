module Users
  class CreateService
    def self.call(clerk_token:, nickname:, username:)
      clerk_payload = ClerkClient.verify(clerk_token)

      if User.exists?(clerk_user_id: clerk_payload[:clerk_user_id])
        raise AccountAlreadyExistsError
      end

      if User.exists?(username: username&.downcase)
        raise UsernameTakenError
      end

      user = User.create!(
        clerk_user_id: clerk_payload[:clerk_user_id],
        email: clerk_payload[:email],
        nickname: nickname,
        username: username
      )

      access_token  = TokenIssuer.issue_access_token(user)
      refresh_token = TokenIssuer.issue_refresh_token(user)

      RefreshToken.create!(
        user: user,
        token: refresh_token,
        expires_at: TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now
      )

      Rails.logger.info "ユーザー登録成功: user_id=#{user.id}"
      { access_token: access_token, refresh_token: refresh_token }
    end
  end
end

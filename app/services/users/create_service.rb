module Users
  class CreateService
    def self.call(clerk_token:, nickname:, username:)
      # ClerkのJWTを検証し、ペイロードからユーザー情報を取得する
      clerk_payload = ClerkClient.verify(clerk_token)

      # Clerk側のユーザーIDが既にローカルDBに存在する場合は二重登録とみなす
      if User.exists?(clerk_user_id: clerk_payload[:clerk_user_id])
        raise AccountAlreadyExistsError
      end

      # Modelのnormalize_usernameより前に実行されるため、重複チェック時も大文字小文字を統一する
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
      refresh_token_expires_at = TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now

      # リフレッシュトークンはDBで管理し、失効・ローテーションを可能にする
      RefreshToken.create!(
        user: user,
        token: refresh_token,
        expires_at: refresh_token_expires_at
      )

      Rails.logger.info "ユーザー登録成功: user_id=#{user.id}"
      {
        access_token: access_token,
        refresh_token: refresh_token,
        refresh_token_expires_at: refresh_token_expires_at
      }
    end
  end
end

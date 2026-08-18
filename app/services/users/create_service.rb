module Users
  class CreateService
    def self.call(signup_token:, nickname:, username:)
      # コールバックで本人確認済みの情報を signup_token 経由で受け取る。
      # フロントから provider / uid / email を送らせない（詐称を防ぐ）
      payload = TokenIssuer.decode_signup_token(signup_token)
      raise UnauthorizedError unless payload

      if UserIdentity.exists?(provider: payload["provider"], provider_uid: payload["uid"])
        raise AccountAlreadyExistsError
      end

      # Modelのnormalize_usernameより前に実行されるため、重複チェック時も大文字小文字を統一する
      if User.exists?(username: username&.downcase)
        raise UsernameTakenError
      end

      user          = nil
      refresh_token = nil
      refresh_token_expires_at = TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now

      # 3つが揃って初めてログインできる状態になる。途中で落ちると
      # 「連携先が無い」「セッションが張れない」ユーザーが残るため1トランザクションにする
      ActiveRecord::Base.transaction do
        user = User.create!(
          email: payload["email"],
          nickname: nickname,
          username: username
        )
        UserIdentity.create!(
          user: user,
          provider: payload["provider"],
          provider_uid: payload["uid"],
          email: payload["email"]
        )
        refresh_token = TokenIssuer.issue_refresh_token(user)
        # リフレッシュトークンはDBで管理し、失効・ローテーションを可能にする
        RefreshToken.create!(
          user: user,
          token: refresh_token,
          expires_at: refresh_token_expires_at
        )
      end

      Rails.logger.info "ユーザー登録成功: user_id=#{user.id}"
      {
        access_token: TokenIssuer.issue_access_token(user),
        refresh_token: refresh_token,
        refresh_token_expires_at: refresh_token_expires_at
      }
    end
  end
end

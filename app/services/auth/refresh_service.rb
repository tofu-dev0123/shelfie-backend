module Auth
  class RefreshService
    def self.call(refresh_token:)
      raise InvalidRefreshTokenError if refresh_token.blank?

      record = RefreshToken.valid.find_by(token: refresh_token)
      raise InvalidRefreshTokenError unless record

      user = record.user
      access_token = TokenIssuer.issue_access_token(user)

      if record.expires_at <= AuthConstants::REFRESH_ROTATION_THRESHOLD.from_now
        record.destroy
        new_refresh_token = TokenIssuer.issue_refresh_token(user)
        RefreshToken.create!(
          user: user,
          token: new_refresh_token,
          expires_at: TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now
        )
        Rails.logger.info "リフレッシュトークンをローテーションしました: user_id=#{user.id}"
        { access_token: access_token, new_refresh_token: new_refresh_token }
      else
        Rails.logger.info "アクセストークンを再発行しました: user_id=#{user.id}"
        { access_token: access_token, new_refresh_token: nil }
      end
    end
  end
end

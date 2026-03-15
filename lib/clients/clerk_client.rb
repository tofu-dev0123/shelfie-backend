class ClerkClient
  class UnauthorizedError < StandardError; end

  def self.verify(token)
    if Rails.env.development? && (dev_secret = ENV["DEV_JWT_SECRET"]).present?
      dev_payload = try_dev_token(token, dev_secret)
      return dev_payload if dev_payload
    end

    Rails.logger.info "Clerk API 呼び出し開始"
    payload = Clerk::Token.decode(token)
    Rails.logger.info "Clerk API 呼び出し成功"
    {
      clerk_user_id: payload["sub"],
      email: payload.dig("email_addresses", 0, "email_address") || payload["email"]
    }
  rescue StandardError => e
    Rails.logger.warn "Clerk API 呼び出し失敗: #{e.message}"
    raise UnauthorizedError
  end

  def self.try_dev_token(token, secret)
    payload = JWT.decode(token, secret, true, algorithms: ["HS256"]).first
    Rails.logger.info "開発用トークンで認証成功"
    { clerk_user_id: payload["sub"], email: payload["email"] }
  rescue JWT::DecodeError
    nil
  end
  private_class_method :try_dev_token
end

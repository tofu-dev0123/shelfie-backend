class ClerkClient
  class UnauthorizedError < StandardError; end

  def self.verify(token)
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
end

class ClerkClient
  class UnauthorizedError < StandardError; end

  def self.verify(token)
    payload = Clerk::Token.decode(token)
    {
      clerk_user_id: payload["sub"],
      email: payload.dig("email_addresses", 0, "email_address") || payload["email"]
    }
  rescue StandardError
    raise UnauthorizedError
  end
end

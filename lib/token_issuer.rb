module TokenIssuer
  ACCESS_TOKEN_EXPIRY  = 60.minutes
  REFRESH_TOKEN_EXPIRY = 30.days

  def self.issue_access_token(user)
    payload = { user_id: user.id, exp: ACCESS_TOKEN_EXPIRY.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end

  def self.issue_refresh_token(user)
    payload = { user_id: user.id, exp: REFRESH_TOKEN_EXPIRY.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end

  def self.decode(token)
    JWT.decode(token, Rails.application.secret_key_base, true, algorithms: [ "HS256" ]).first
  rescue JWT::DecodeError
    nil
  end
end

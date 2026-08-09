module TokenIssuer
  ACCESS_TOKEN_EXPIRY  = 60.minutes
  REFRESH_TOKEN_EXPIRY = 30.days

  # payload の purpose クレームに入れる値。
  # access と refresh は同じ鍵で署名されるため、種別はトークンの中にしか書けない。
  PURPOSE_ACCESS  = "access"
  PURPOSE_REFRESH = "refresh"

  def self.issue_access_token(user)
    payload = { user_id: user.id, purpose: PURPOSE_ACCESS, exp: ACCESS_TOKEN_EXPIRY.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end

  def self.issue_refresh_token(user)
    payload = { user_id: user.id, purpose: PURPOSE_REFRESH, exp: REFRESH_TOKEN_EXPIRY.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end

  # purpose を必須にしているのは、呼び出し側が種別の検証を省略できないようにするため。
  # 30日有効な refresh_token をアクセストークンとして使い回されるのを防ぐ。
  #
  # 逆方向（access_token をリフレッシュに使う）は Auth::RefreshService が
  # refresh_tokens テーブルの照合で完結しており、発行時に保存していない
  # access_token はその時点で弾かれるため、ここでの検証は不要。
  def self.decode(token, purpose:)
    payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithms: [ "HS256" ]).first
    return nil unless payload["purpose"] == purpose

    payload
  rescue JWT::DecodeError
    nil
  end
end

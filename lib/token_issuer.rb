module TokenIssuer
  # 4種のトークンすべての署名鍵。Rails 本体の汎用鍵（署名 Cookie・signed_id 等に使うもの）
  # とは分ける。共有すると認証トークンだけをローテーションできず、
  # 漏洩時の影響範囲も広がるため。経緯は docs/architecture/auth.md を参照。
  #
  # メソッド内の ENV.fetch ではなく定数で受けているのは、未設定を
  # 「最初にトークンを発行した瞬間」ではなく「production の起動時」に落とすため。
  # lib は eager load されるので、この行が起動時に評価される。
  # ただし rake タスクは rake_eager_load が既定 false のため評価されない
  # （マイグレーションのジョブがこの鍵を必要としないのはこのため）。
  #
  # 未設定だけでなく空文字も弾く。env_file 経由だとキー自体は定義されるため、
  # ENV.fetch の既定値では「設定したのに空の鍵で署名する」を防げない。
  #
  # 開発とテストは .env.local を用意しなくても動くよう既定値を持つが、
  # production ではフォールバックしない。
  SECRET_KEY =
    if Rails.env.production?
      ENV["JWT_SECRET_KEY"].presence || raise(KeyError, "JWT_SECRET_KEY が設定されていません")
    else
      ENV["JWT_SECRET_KEY"].presence || "development_and_test_only_jwt_secret_key"
    end

  ACCESS_TOKEN_EXPIRY  = 60.minutes
  REFRESH_TOKEN_EXPIRY = 30.days
  # サインアップ画面で nickname / username を入力しきるのに足りて、
  # 漏れたときの窓が短い長さ。
  SIGNUP_TOKEN_EXPIRY  = 10.minutes

  # payload の purpose クレームに入れる値。
  # access と refresh と signup は同じ鍵で署名されるため、種別はトークンの中にしか書けない。
  PURPOSE_ACCESS  = "access"
  PURPOSE_REFRESH = "refresh"
  PURPOSE_SIGNUP  = "signup"

  def self.issue_access_token(user)
    payload = { user_id: user.id, purpose: PURPOSE_ACCESS, exp: ACCESS_TOKEN_EXPIRY.from_now.to_i }
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.issue_refresh_token(user)
    payload = { user_id: user.id, purpose: PURPOSE_REFRESH, exp: REFRESH_TOKEN_EXPIRY.from_now.to_i }
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  # ユーザーレコードがまだ無い状態の本人確認済み情報を、サインアップ完了まで運ぶ。
  # サーバー側に保存しないのは、離脱したサインアップの残骸を溜めないため。
  def self.issue_signup_token(identity)
    payload = {
      purpose:  PURPOSE_SIGNUP,
      provider: identity.provider,
      uid:      identity.uid,
      email:    identity.email,
      name:     identity.name,
      exp:      SIGNUP_TOKEN_EXPIRY.from_now.to_i
    }
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.decode_signup_token(token)
    decode(token, purpose: PURPOSE_SIGNUP)
  end

  # purpose を必須にしているのは、呼び出し側が種別の検証を省略できないようにするため。
  # 30日有効な refresh_token をアクセストークンとして使い回されるのを防ぐ。
  #
  # 逆方向（access_token をリフレッシュに使う）は Auth::RefreshService が
  # refresh_tokens テーブルの照合で完結しており、発行時に保存していない
  # access_token はその時点で弾かれるため、ここでの検証は不要。
  def self.decode(token, purpose:)
    payload = JWT.decode(token, SECRET_KEY, true, algorithms: [ "HS256" ]).first
    return nil unless payload["purpose"] == purpose

    payload
  rescue JWT::DecodeError
    nil
  end
end

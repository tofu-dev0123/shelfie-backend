module Oauth
  # 認可リクエスト〜コールバックの間だけ生きる往復データ。
  # サーバー側に状態を持たないため api_only を崩さずに済む。
  module State
    EXPIRY = 10.minutes

    PURPOSE = "oauth_state"

    # RFC 7636 の code_verifier は 43〜128 文字。64 バイトの urlsafe_base64 は 86 文字で収まる。
    CODE_VERIFIER_BYTES = 64
    STATE_BYTES         = 32

    # => [ cookie_value, state, code_challenge ]
    def self.issue(provider:, intent: "auth")
      state         = SecureRandom.urlsafe_base64(STATE_BYTES)
      code_verifier = SecureRandom.urlsafe_base64(CODE_VERIFIER_BYTES)
      payload = {
        purpose:       PURPOSE,
        provider:      provider,
        intent:        intent,
        state:         state,
        code_verifier: code_verifier,
        exp:           EXPIRY.from_now.to_i
      }
      [ JWT.encode(payload, secret, "HS256"), state, code_challenge(code_verifier) ]
    end

    # 改竄・期限切れ・purpose 違いはすべて nil に潰す。
    # 呼び出し側はどれであっても invalid_state として同じ扱いにするため。
    def self.decode(cookie)
      return nil if cookie.blank?

      payload = JWT.decode(cookie, secret, true, algorithms: [ "HS256" ]).first
      payload["purpose"] == PURPOSE ? payload : nil
    rescue JWT::DecodeError
      nil
    end

    # PKCE S256: BASE64URL(SHA256(code_verifier))、パディングなし
    def self.code_challenge(verifier)
      Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    end
    private_class_method :code_challenge

    # 署名鍵は TokenIssuer と共有する。oauth_state も認証フローの一部で、
    # ローテーションの単位を分ける理由が無いため（鍵の定義は1箇所に置く）。
    def self.secret = TokenIssuer::SECRET_KEY
    private_class_method :secret
  end
end

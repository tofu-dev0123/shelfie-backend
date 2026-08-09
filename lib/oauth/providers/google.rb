module Oauth
  module Providers
    class Google < Base
      NAME               = "google"
      AUTHORIZE_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth"
      TOKEN_ENDPOINT     = "https://oauth2.googleapis.com/token"
      SCOPE              = "openid email profile"
      ISSUERS            = [ "accounts.google.com", "https://accounts.google.com" ].freeze

      class << self
        private

        def build_identity(token)
          claims = verified_claims(token[:id_token])
          Identity.new(provider: NAME, uid: claims["sub"],
                       email: claims["email"], name: claims["name"])
        end

        # id_token を token endpoint から TLS 越しに直接受領しているため、
        # OIDC Core 3.1.3.7 により署名検証は TLS のサーバー検証で代替できる（JWKS 不要）。
        # ただし以下は必ず検証する。ここを落とすと検証しない意味がなくなる。
        # とくに aud を落とすと、他アプリ向けに発行された正規のトークンでなりすませる。
        def verified_claims(id_token)
          raise ProviderError, "id_token がありません" if id_token.blank?

          claims = decode_without_verification(id_token)
          raise ProviderError, "iss 不正"     unless ISSUERS.include?(claims["iss"])
          raise ProviderError, "aud 不正"     unless claims["aud"] == client_id
          raise ProviderError, "exp 切れ"     unless claims["exp"].to_i > Time.current.to_i
          raise ProviderError, "メール未検証" unless claims["email_verified"]

          claims
        end

        def decode_without_verification(id_token)
          JWT.decode(id_token, nil, false).first
        rescue JWT::DecodeError => e
          raise ProviderError, "id_token を解析できません: #{e.message}"
        end
      end
    end
  end
end

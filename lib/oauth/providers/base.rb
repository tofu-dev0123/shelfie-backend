# net/http は default gem で Gemfile に無いため Bundler.require では読まれない。
# 開発とテストでは他の gem が間接的に読むので気づけないが、production では
# Net::HTTP が未定義になる。使う側で明示的に require する。
require "net/http"

module Oauth
  module Providers
    # サブクラスは NAME / AUTHORIZE_ENDPOINT / TOKEN_ENDPOINT / SCOPE と
    # build_identity(token) を定義する。プロバイダ差はこの build_identity に閉じる。
    class Base
      class << self
        def authorize_url(state:, code_challenge:)
          uri = URI(self::AUTHORIZE_ENDPOINT)
          uri.query = URI.encode_www_form(
            client_id:             client_id,
            redirect_uri:          redirect_uri,
            response_type:         "code",
            scope:                 self::SCOPE,
            state:                 state,
            code_challenge:        code_challenge,
            code_challenge_method: "S256"
          )
          uri.to_s
        end

        def fetch_identity(code:, code_verifier:)
          build_identity(exchange_code(code: code, code_verifier: code_verifier))
        end

        def redirect_uri = "#{ENV.fetch('API_BASE_URL')}/auth/#{self::NAME}/callback"

        private

        def client_id     = ENV.fetch("#{self::NAME.upcase}_OAUTH_CLIENT_ID")
        def client_secret = ENV.fetch("#{self::NAME.upcase}_OAUTH_CLIENT_SECRET")

        # 認可コードをトークンに交換する。TLS 越しの server-to-server 通信。
        # フロントを経由しないため、返ってきたトークンは定義上このアプリのもの。
        def exchange_code(code:, code_verifier:)
          uri = URI(self::TOKEN_ENDPOINT)
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            request = Net::HTTP::Post.new(uri)
            # GitHub は既定で form-encoded を返すため明示する
            request["Accept"] = "application/json"
            request.set_form_data(
              client_id:     client_id,
              client_secret: client_secret,
              code:          code,
              code_verifier: code_verifier,
              redirect_uri:  redirect_uri,
              grant_type:    "authorization_code"
            )
            http.request(request)
          end
          raise ProviderError, "token endpoint: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          parse_json(response.body).tap do |body|
            # GitHub は失敗時も 200 で { error: ... } を返す
            raise ProviderError, body[:error].to_s if body.is_a?(Hash) && body[:error].present?
          end
        end

        def parse_json(body)
          JSON.parse(body.to_s, symbolize_names: true)
        rescue JSON::ParserError
          # JSON::ParserError の message はエラー位置周辺の最大32文字を含む（先頭とは限らない）。
          # トークンエンドポイントのレスポンス本文（アクセストークンを含みうる）が
          # ログに出るため載せない。
          raise ProviderError, "レスポンスが JSON ではありません"
        end

        def build_identity(_token) = raise NotImplementedError
      end
    end
  end
end

require "net/http"

module Oauth
  module Providers
    class Github < Base
      NAME               = "github"
      AUTHORIZE_ENDPOINT = "https://github.com/login/oauth/authorize"
      TOKEN_ENDPOINT     = "https://github.com/login/oauth/access_token"
      SCOPE              = "read:user user:email"
      API_BASE           = "https://api.github.com"

      class << self
        private

        def build_identity(token)
          access_token = token[:access_token]
          user = api_get("#{API_BASE}/user", access_token)
          Identity.new(
            provider: NAME,
            uid:      user[:id].to_s,                       # 整数で返るので文字列化する
            email:    primary_verified_email(access_token),
            name:     user[:name].presence || user[:login]  # name は null になりうる
          )
        end

        # GitHub はメール非公開設定が可能なため /user では取れないことがある
        def primary_verified_email(access_token)
          found = api_get("#{API_BASE}/user/emails", access_token)
                    .find { |email| email[:primary] && email[:verified] }
          raise EmailUnavailableError unless found

          found[:email]
        end

        def api_get(url, access_token)
          uri = URI(url)
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            request = Net::HTTP::Get.new(uri)
            request["Authorization"] = "Bearer #{access_token}"
            request["Accept"]        = "application/vnd.github+json"
            http.request(request)
          end
          raise ProviderError, "#{url}: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          parse_json(response.body)
        end
      end
    end
  end
end

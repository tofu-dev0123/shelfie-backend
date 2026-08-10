module Oauth
  # 認可リクエストの入口。state / PKCE を発行して IdP の認可 URL を組み立てる。
  class StartService
    # v1 で使うのはログイン目的のみ。既存アカウントへの追加連携（link）は v2 のスコープ。
    DEFAULT_INTENT = "auth".freeze

    def self.call(provider:, intent: nil)
      state_cookie, state, code_challenge = State.issue(
        provider: provider,
        intent: intent.presence || DEFAULT_INTENT
      )

      authorize_url = Providers.fetch(provider).authorize_url(
        state: state,
        code_challenge: code_challenge
      )

      Rails.logger.info "認可リクエスト発行: provider=#{provider}"
      { authorize_url: authorize_url, state_cookie: state_cookie }
    end
  end
end

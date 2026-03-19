module V1
  class BaseController < ApplicationController
    include ErrorHandler

    private

    def clerk_token_from_header
      request.headers["Authorization"]&.delete_prefix("Bearer ")
    end

    # Logrageの構造化ログにuser_idを追加するためにオーバーライドしている
    def append_info_to_payload(payload)
      super
      payload[:user_id] = current_user&.id
    end

    # トークンがある場合のみ認証する。トークンがない場合は current_user = nil のまま通過
    # トークンが不正・期限切れの場合は ClerkClient::UnauthorizedError を raise → 401
    def authenticate_user_if_token_present
      token = clerk_token_from_header
      return unless token

      payload = TokenIssuer.decode(token)
      raise ClerkClient::UnauthorizedError unless payload

      @current_user = User.find_by(id: payload["user_id"])
      raise ClerkClient::UnauthorizedError unless @current_user
    end

    def current_user
      @current_user
    end
  end
end

module V1
  class BaseController < ApplicationController
    include ErrorHandler

    private

    def access_token_from_header
      request.headers["Authorization"]&.delete_prefix("Bearer ")
    end

    # Logrageの構造化ログにuser_idを追加するためにオーバーライドしている
    def append_info_to_payload(payload)
      super
      payload[:user_id] = current_user&.id
    end

    # トークンが必須。トークンがない・不正・期限切れ・purpose が access でない場合は
    # UnauthorizedError を raise → 401
    def authenticate_user!
      token = access_token_from_header
      raise UnauthorizedError unless token

      payload = TokenIssuer.decode(token, purpose: TokenIssuer::PURPOSE_ACCESS)
      raise UnauthorizedError unless payload

      @current_user = User.find_by(id: payload["user_id"])
      raise UnauthorizedError unless @current_user
    end

    def current_user
      @current_user
    end
  end
end

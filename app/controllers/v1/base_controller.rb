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

    def current_user
      nil
    end
  end
end

module V1
  class BaseController < ApplicationController
    include ErrorHandler

    private

    def clerk_token_from_header
      request.headers["Authorization"]&.delete_prefix("Bearer ")
    end

    def append_info_to_payload(payload)
      super
      payload[:user_id] = current_user&.id
    end

    def current_user
      nil
    end
  end
end

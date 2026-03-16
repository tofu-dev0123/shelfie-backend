module V1
  module Auth
    class SessionsController < V1::BaseController
      def login
        Rails.logger.debug "SessionsController#login に入りました"
        result = ::Auth::LoginService.call(
          clerk_token: clerk_token_from_header
        )

        response.set_cookie(
          :refresh_token,
          value: result[:refresh_token],
          httponly: true,
          secure: true,
          same_site: :lax,
          domain: Rails.application.config.cookie_domain,
          expires: TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now
        )

        render json: { access_token: result[:access_token] }, status: :ok
      end
    end
  end
end

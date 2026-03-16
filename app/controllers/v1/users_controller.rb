module V1
  class UsersController < BaseController
    def create
      Rails.logger.debug "UsersController#create に入りました"
      result = Users::CreateService.call(
        clerk_token: clerk_token_from_header,
        nickname: user_params[:nickname],
        username: user_params[:username]
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

      render json: { access_token: result[:access_token] }, status: :created
    end

    private

    def user_params
      params.permit(:nickname, :username)
    end

    def clerk_token_from_header
      request.headers["Authorization"]&.delete_prefix("Bearer ")
    end
  end
end

module V1
  class UsersController < BaseController
    before_action :authenticate_user_if_token_present, only: [ :show ]

    def show
      Rails.logger.debug "UsersController#show に入りました"
      result = Users::ShowService.call(username: params[:username], current_user: current_user)
      render json: UserSerializer.new(**result.except(:user), user: result[:user]).as_json, status: :ok
    end

    def check_username
      Rails.logger.debug "UsersController#check_username に入りました"
      result = Users::CheckUsernameService.call(value: params[:value])
      render json: result, status: :ok
    end

    def create
      Rails.logger.debug "UsersController#create に入りました"
      result = Users::CreateService.call(
        clerk_token: clerk_token_from_header,
        nickname: user_params[:nickname],
        username: user_params[:username]
      )

      # httponly: JSからアクセス不可にしてXSS対策、secure: HTTPS限定、same_site: laxでCSRF対策しつつ通常のリンク遷移は許容
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
  end
end

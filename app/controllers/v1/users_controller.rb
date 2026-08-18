module V1
  class UsersController < BaseController
    include RefreshTokenCookie
    include SignupTokenCookie

    def show
      Rails.logger.debug "UsersController#show に入りました"
      result = Users::ShowService.call(username: params[:username])
      render json: UserSerializer.new(**result).as_json, status: :ok
    end

    def check_username
      Rails.logger.debug "UsersController#check_username に入りました"
      result = Users::CheckUsernameService.call(value: params[:value])
      render json: result, status: :ok
    end

    def create
      Rails.logger.debug "UsersController#create に入りました"
      result = Users::CreateService.call(
        signup_token: cookies[:signup_token],
        nickname: user_params[:nickname],
        username: user_params[:username]
      )

      set_refresh_token_cookie(result[:refresh_token], expires_at: result[:refresh_token_expires_at])
      # 役目を終えたサインアップ用 Cookie は残さない
      clear_signup_token_cookie

      render json: { access_token: result[:access_token] }, status: :created
    end

    private

    def user_params
      params.permit(:nickname, :username)
    end
  end
end

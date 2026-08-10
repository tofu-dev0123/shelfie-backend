module V1
  module Auth
    class SignupsController < V1::BaseController
      include SignupTokenCookie

      def show
        Rails.logger.debug "SignupsController#show に入りました"
        result = ::Auth::SignupContextService.call(signup_token: cookies[:signup_token])

        render json: result, status: :ok
      end
    end
  end
end

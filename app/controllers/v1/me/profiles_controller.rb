module V1
  module Me
    class ProfilesController < BaseController
      def show
        Rails.logger.debug "V1::Me::ProfilesController#show: user_id=#{current_user.id}"
        result = Users::MeShowService.call(current_user: current_user)
        render json: UserSerializer.new(**result, include_id: true).as_json, status: :ok
      end
    end
  end
end

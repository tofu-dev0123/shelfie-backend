module V1
  module Me
    class ProfilesController < BaseController
      def show
        Rails.logger.debug "V1::Me::ProfilesController#show: user_id=#{current_user.id}"
        result = Users::MeShowService.call(current_user: current_user)
        render json: UserSerializer.new(**result, include_id: true).as_json, status: :ok
      end

      def update
        Rails.logger.debug "V1::Me::ProfilesController#update: user_id=#{current_user.id}"
        user = Users::MeUpdateService.call(current_user: current_user, attrs: profile_params.to_h)
        render json: UserProfileSerializer.new(user).as_json, status: :ok
      end

      private

      def profile_params
        params.permit(:nickname, :bio, links: [])
      end
    end
  end
end

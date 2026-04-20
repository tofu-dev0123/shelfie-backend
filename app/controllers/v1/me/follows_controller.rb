module V1
  module Me
    class FollowsController < BaseController
      def create
        Rails.logger.debug "V1::Me::FollowsController#create: user_id=#{current_user.id} username=#{params[:username]}"
        Follows::CreateService.call(current_user: current_user, username: params[:username])
        render json: { message: I18n.t("messages.me.follows.created") }, status: :created
      end

      def destroy
        Rails.logger.debug "V1::Me::FollowsController#destroy: user_id=#{current_user.id} username=#{params[:username]}"
        Follows::DestroyService.call(current_user: current_user, username: params[:username])
        render json: { message: I18n.t("messages.me.follows.destroyed") }, status: :ok
      end
    end
  end
end

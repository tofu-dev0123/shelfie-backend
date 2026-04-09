module V1
  module Me
    class AvatarsController < BaseController
      def create
        Rails.logger.debug "V1::Me::AvatarsController#create: user_id=#{current_user.id}"
        avatar_url = Avatars::UploadService.call(current_user: current_user, file: params[:avatar])
        render json: { avatar_url: avatar_url }, status: :ok
      end

      def destroy
        Rails.logger.debug "V1::Me::AvatarsController#destroy: user_id=#{current_user.id}"
        Avatars::DestroyService.call(current_user: current_user)
        render json: { message: I18n.t("messages.me.avatar.deleted") }, status: :ok
      end
    end
  end
end

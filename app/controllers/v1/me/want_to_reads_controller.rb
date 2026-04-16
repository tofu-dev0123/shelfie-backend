module V1
  module Me
    class WantToReadsController < BaseController
      def index
        Rails.logger.debug "V1::Me::WantToReadsController#index: user_id=#{current_user.id}"
        result = WantToReads::IndexService.call(
          current_user: current_user,
          cursor: params[:cursor],
          limit: params[:limit]
        )
        render json: result, status: :ok
      end

      def create
        Rails.logger.debug "V1::Me::WantToReadsController#create: user_id=#{current_user.id} isbn=#{params[:isbn]}"
        WantToReads::CreateService.call(current_user: current_user, isbn: params[:isbn])
        render json: { message: I18n.t("messages.me.want_to_reads.created") }, status: :created
      end

      def destroy
        Rails.logger.debug "V1::Me::WantToReadsController#destroy: user_id=#{current_user.id} isbn=#{params[:isbn]}"
        WantToReads::DestroyService.call(current_user: current_user, isbn: params[:isbn])
        render json: { message: I18n.t("messages.me.want_to_reads.destroyed") }, status: :ok
      end
    end
  end
end

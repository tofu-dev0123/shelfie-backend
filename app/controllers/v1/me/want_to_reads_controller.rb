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
    end
  end
end

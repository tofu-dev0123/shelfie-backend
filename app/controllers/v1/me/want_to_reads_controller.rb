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
        render json: { message: "読みたいリストに追加しました" }, status: :created
      end
    end
  end
end

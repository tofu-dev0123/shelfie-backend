module V1
  class FeedController < BaseController
    before_action :authenticate_user_if_token_present

    def index
      Rails.logger.debug "FeedController#index に入りました"
      result = Feed::IndexService.call(
        current_user: current_user,
        cursor: params[:cursor],
        limit: params[:limit]
      )
      render json: result, status: :ok
    end
  end
end

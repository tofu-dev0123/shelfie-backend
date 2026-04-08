module V1
  class UserBooksController < BaseController
    def index
      Rails.logger.debug "UserBooksController#index に入りました"
      result = UserBooks::IndexService.call(
        username: params[:user_username],
        cursor: params[:cursor],
        limit: params[:limit]
      )
      render json: result, status: :ok
    end
  end
end

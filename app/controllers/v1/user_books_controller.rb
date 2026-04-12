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

    def show
      Rails.logger.debug "UserBooksController#show に入りました"
      result = UserBooks::ShowService.call(
        username: params[:user_username],
        isbn: params[:isbn]
      )
      render json: UserBookShowSerializer.new(result[:user_book], result[:user]).as_json, status: :ok
    end
  end
end

module V1
  class BooksController < BaseController
    before_action :authenticate_user!

    def search
      Rails.logger.debug "BooksController#search に入りました"
      result = Books::SearchService.call(
        q: params[:q],
        cursor: params[:cursor]
      )
      render json: result, status: :ok
    end
  end
end

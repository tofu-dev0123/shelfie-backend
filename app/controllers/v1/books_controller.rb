module V1
  class BooksController < BaseController
    before_action :authenticate_user!, only: [ :search ]

    def search
      Rails.logger.debug "BooksController#search に入りました"
      result = Books::SearchService.call(
        q: params[:q],
        cursor: params[:cursor]
      )
      render json: result, status: :ok
    end

    def users
      Rails.logger.debug "BooksController#users に入りました"
      result = Books::ReadersService.call(
        google_books_id: params[:google_books_id],
        cursor: params[:cursor],
        limit: params[:limit]
      )
      render json: result, status: :ok
    end
  end
end

module V1
  class BooksController < BaseController
    before_action :authenticate_user!, only: [ :search, :show ]

    def search
      Rails.logger.debug "BooksController#search に入りました"
      result = Books::SearchService.call(
        q: params[:q],
        cursor: params[:cursor],
        current_user: current_user
      )
      render json: result, status: :ok
    end

    def show
      Rails.logger.debug "BooksController#show に入りました"
      result = Books::ShowService.call(isbn: params[:isbn], current_user: current_user)
      render json: result, status: :ok
    end

    def users
      Rails.logger.debug "BooksController#users に入りました"
      result = Books::ReadersService.call(
        isbn: params[:isbn],
        cursor: params[:cursor],
        limit: params[:limit]
      )
      render json: result, status: :ok
    end
  end
end

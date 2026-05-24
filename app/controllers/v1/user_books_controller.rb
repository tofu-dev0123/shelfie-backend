module V1
  class UserBooksController < BaseController
    # 認証は任意。Authorization ヘッダがあれば current_user を解決し、is_in_my_want_to_read の判定に使う
    before_action :authenticate_user_if_token_present

    def index
      Rails.logger.debug "UserBooksController#index に入りました"
      result = UserBooks::IndexService.call(
        username: params[:user_username],
        cursor: params[:cursor],
        limit: params[:limit],
        current_user: current_user
      )
      render json: result, status: :ok
    end

    def show
      Rails.logger.debug "UserBooksController#show に入りました"
      result = UserBooks::ShowService.call(
        username: params[:user_username],
        isbn: params[:isbn],
        current_user: current_user
      )
      render json: UserBookShowSerializer.new(
        result[:user_book],
        result[:user],
        want_to_read_isbns: result[:want_to_read_isbns]
      ).as_json, status: :ok
    end
  end
end

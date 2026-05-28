module V1
  class PostsController < BaseController
    before_action :authenticate_user_if_token_present

    def search
      Rails.logger.debug "PostsController#search に入りました"
      result = Posts::SearchService.call(
        q: params[:q],
        tag: params[:tag],
        current_user: current_user,
        cursor: params[:cursor],
        limit: params[:limit]
      )
      render json: result, status: :ok
    end
  end
end

module V1
  class PostsController < BaseController
    def search
      Rails.logger.debug "PostsController#search に入りました"
      result = Posts::SearchService.call(
        q: params[:q],
        tag: params[:tag],
        cursor: params[:cursor],
        limit: params[:limit]
      )
      render json: result, status: :ok
    end
  end
end

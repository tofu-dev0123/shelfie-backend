module V1
  class TagsController < BaseController
    def index
      Rails.logger.debug "TagsController#index: q=#{params[:q]}"
      tags = Tags::SuggestService.call(q: params[:q])
      render json: { tags: TagSerializer.render_collection(tags) }, status: :ok
    end
  end
end

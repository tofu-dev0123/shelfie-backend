module V1
  class TagsController < BaseController
    def index
      Rails.logger.debug "TagsController#index に入りました"
      tags = Tags::ListService.call
      expires_in TagConstants::CACHE_MAX_AGE, public: true
      render json: { tags: TagSerializer.render_collection(tags) }, status: :ok
    end
  end
end

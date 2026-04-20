module V1
  class UserFollowsController < BaseController
    def followers
      Rails.logger.debug "V1::UserFollowsController#followers: username=#{params[:username]}"
      result = Follows::FollowersService.call(
        username: params[:username],
        cursor:   params[:cursor],
        limit:    params[:limit]
      )
      render json: result, status: :ok
    end

    def following
      Rails.logger.debug "V1::UserFollowsController#following: username=#{params[:username]}"
      result = Follows::FollowingService.call(
        username: params[:username],
        cursor:   params[:cursor],
        limit:    params[:limit]
      )
      render json: result, status: :ok
    end
  end
end

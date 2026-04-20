class FollowUserSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      username:   @user.username,
      nickname:   @user.nickname,
      avatar_url: avatar_url
    }
  end

  private

  def avatar_url
    return nil if @user.avatar_key.nil?

    "https://#{CdnConstants::CLOUDFRONT_HOST}/#{@user.avatar_key}"
  end
end

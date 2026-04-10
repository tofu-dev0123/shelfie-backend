class UserSerializer
  def initialize(user:, followers_count:, following_count:, books_count:, links:, is_following: nil, is_me: nil, include_id: false)
    @user            = user
    @followers_count = followers_count
    @following_count = following_count
    @books_count     = books_count
    @links           = links
    @is_following    = is_following
    @is_me           = is_me
    @include_id      = include_id
  end

  def as_json
    json = {}
    json[:id] = @user.id if @include_id
    json.merge!(
      username:        @user.username,
      nickname:        @user.nickname,
      bio:             @user.bio,
      avatar_url:      avatar_url,
      followers_count: @followers_count,
      following_count: @following_count,
      books_count:     @books_count,
      links:           @links
    )

    # 認証済みの場合のみ is_following / is_me を含める
    json[:is_following] = @is_following unless @is_following.nil?
    json[:is_me]        = @is_me        unless @is_me.nil?

    json
  end

  private

  def avatar_url
    return nil if @user.avatar_key.nil?

    "https://#{CdnConstants::CLOUDFRONT_HOST}/#{@user.avatar_key}"
  end
end

class UserSerializer
  def initialize(user:, followers_count:, following_count:, books_count:, links:, include_id: false, **_ignored)
    @user            = user
    @followers_count = followers_count
    @following_count = following_count
    @books_count     = books_count
    @links           = links
    @include_id      = include_id
  end

  def as_json
    json = {}
    json[:id] = @user.id if @include_id
    json.merge!(
      username:        @user.username,
      nickname:        @user.nickname,
      bio:             @user.bio,
      followers_count: @followers_count,
      following_count: @following_count,
      books_count:     @books_count,
      links:           @links
    )
    json
  end
end

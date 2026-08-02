class UserSummarySerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      username: @user.username,
      nickname: @user.nickname
    }
  end
end

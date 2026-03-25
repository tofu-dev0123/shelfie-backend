# PATCH /v1/me のレスポンス専用シリアライザ。
# フル情報（カウント等）を返す UserSerializer とは責務を分けている。
class UserProfileSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      nickname: @user.nickname,
      bio:      @user.bio,
      links:    @user.links
    }
  end
end

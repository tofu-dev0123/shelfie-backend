# PATCH /v1/me のレスポンス専用シリアライザ。
# 仕様上、プロフィール更新APIは更新対象フィールド（nickname / bio）のみを返す。
# フル情報（カウント・リンク等）を返す UserSerializer とは責務を分けている。
class UserProfileSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      nickname: @user.nickname,
      bio:      @user.bio
    }
  end
end

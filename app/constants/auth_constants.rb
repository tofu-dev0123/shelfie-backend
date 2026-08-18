module AuthConstants
  # リフレッシュトークンをローテーションするための残り有効期限の閾値
  # 残り有効期限がこの値以下になった場合、リフレッシュトークンを再発行する（スライディングウィンドウ方式）
  REFRESH_ROTATION_THRESHOLD = 15.days
end

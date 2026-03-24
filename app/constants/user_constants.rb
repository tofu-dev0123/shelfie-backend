module UserConstants
  # 英数字とアンダースコアのみ許可（URLセーフかつSNS的な標準に準拠）
  USERNAME_REGEX      = /\A[a-z0-9_]+\z/
  USERNAME_MIN_LENGTH = 3  # 短すぎるユーザーネームを防ぐための下限
  USERNAME_MAX_LENGTH = 40 # Twitter等のSNS標準に合わせた上限
  NICKNAME_MAX_LENGTH = 50 # UI上の表示崩れを防ぐための上限
  BIO_MAX_LENGTH      = 200 # 自己紹介欄として十分な文字数の上限
end

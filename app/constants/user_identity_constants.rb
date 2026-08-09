module UserIdentityConstants
  # 連携できる外部プロバイダ。DB の (user_id, provider) 一意制約は文字列の完全一致で効くため、
  # 表記ゆれ（"Google" と "google"）を許すと同一プロバイダの二重連携をすり抜ける。
  # provider の桁数はこの許可リストで頭打ちになるため、別途の長さ検証は置かない
  PROVIDERS = %w[google github].freeze

  PROVIDER_UID_MAX_LENGTH = 255 # Google の sub は最大255文字
  EMAIL_MAX_LENGTH        = 254 # RFC 5321 のメールアドレス全体の上限
end

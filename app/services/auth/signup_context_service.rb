module Auth
  # サインアップ画面の初期表示用。フロントは IdP のプロフィールを一切見られないため、
  # nickname のプリフィル元をここから取得する。あわせて signup_token の生死も確認できる。
  class SignupContextService
    def self.call(signup_token:)
      payload = TokenIssuer.decode_signup_token(signup_token)
      raise UnauthorizedError unless payload

      Rails.logger.info "サインアップコンテキスト取得成功: provider=#{payload['provider']}"
      {
        email: payload["email"],
        # name クレームは IdP 側で未設定なら null になる。フロントの入力欄にそのまま
        # 差し込めるよう空文字へ倒す
        nickname_suggestion: payload["name"].to_s
      }
    end
  end
end

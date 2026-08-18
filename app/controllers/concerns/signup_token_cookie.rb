module SignupTokenCookie
  extend ActiveSupport::Concern

  included do
    # ActionController::API はデフォルトで Cookie を扱えないため明示的にインクルードする
    include ActionController::Cookies
  end

  private

  # サインアップ画面（GET /v1/auth/signup_context）と登録（POST /v1/users）の両方へ
  # 送る必要があるため path: "/" にする。refresh_token と同じ扱い
  def set_signup_token_cookie(value)
    response.set_cookie(
      :signup_token,
      value: value,
      httponly: true,
      secure: true,
      same_site: :lax,
      domain: Rails.application.config.cookie_domain,
      path: "/",
      max_age: TokenIssuer::SIGNUP_TOKEN_EXPIRY.to_i
    )
  end

  # path は set 時と同じ値を指定しないとブラウザが削除と判定しない
  def clear_signup_token_cookie
    response.delete_cookie(
      :signup_token,
      domain: Rails.application.config.cookie_domain,
      path: "/"
    )
  end
end

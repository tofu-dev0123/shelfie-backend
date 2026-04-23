module RefreshTokenCookie
  extend ActiveSupport::Concern

  included do
    # ActionController::API はデフォルトで Cookie を扱えないため明示的にインクルードする
    include ActionController::Cookies
  end

  private

  # httponly: JSからアクセス不可にしてXSS対策、secure: HTTPS限定、same_site: laxでCSRF対策しつつ通常のリンク遷移は許容
  # path: "/" を明示しないと Rack は発行時のリクエストパスを Path にセットするため、全パスで Cookie を送信させるために明示する
  def set_refresh_token_cookie(value, expires_at:)
    response.set_cookie(
      :refresh_token,
      value: value,
      httponly: true,
      secure: true,
      same_site: :lax,
      domain: Rails.application.config.cookie_domain,
      path: "/",
      expires: expires_at
    )
  end

  # path は set 時と同じ値を指定しないとブラウザが削除と判定しない
  def clear_refresh_token_cookie
    response.delete_cookie(
      :refresh_token,
      domain: Rails.application.config.cookie_domain,
      path: "/"
    )
  end
end

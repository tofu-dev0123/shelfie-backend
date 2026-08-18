module OauthStateCookie
  extend ActiveSupport::Concern

  included do
    # ActionController::API はデフォルトで Cookie を扱えないため明示的にインクルードする
    include ActionController::Cookies
  end

  # 認可リクエストとコールバックの2アクションでしか使わないため、
  # domain を指定せずホスト限定にし、path でも送信範囲を絞る
  OAUTH_STATE_COOKIE_PATH = "/auth".freeze

  private

  # same_site: :lax は必須。:strict にすると IdP からのトップレベル遷移で Cookie が
  # 送られず、すべてのログインが state 不一致で落ちる
  def set_oauth_state_cookie(value)
    response.set_cookie(
      :oauth_state,
      value: value,
      httponly: true,
      secure: true,
      same_site: :lax,
      path: OAUTH_STATE_COOKIE_PATH,
      max_age: Oauth::State::EXPIRY.to_i
    )
  end

  # path は set 時と同じ値を指定しないとブラウザが削除と判定しない
  def clear_oauth_state_cookie
    response.delete_cookie(:oauth_state, path: OAUTH_STATE_COOKIE_PATH)
  end
end

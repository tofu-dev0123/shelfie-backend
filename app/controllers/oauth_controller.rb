# ブラウザのトップレベル遷移で叩かれる入口。**V1::BaseController を継承しない。**
# ErrorHandler は全例外を JSON で返すが、ここで JSON を返すと生の JSON が
# ページとして表示されてしまう。成否によらず必ずリダイレクトで返す。
class OauthController < ApplicationController
  include OauthStateCookie
  include SignupTokenCookie
  include RefreshTokenCookie

  # フロントの遷移先。docs/api/oauth/callback.md に載る対外契約値なので直書きしない
  HOME_PATH   = "/".freeze
  SIGNUP_PATH = "/signup".freeze
  LOGIN_PATH  = "/login".freeze

  def start
    Rails.logger.debug "OauthController#start に入りました"
    result = Oauth::StartService.call(provider: params[:provider], intent: params[:intent])

    set_oauth_state_cookie(result[:state_cookie])
    redirect_to result[:authorize_url], allow_other_host: true
  end

  def callback
    Rails.logger.debug "OauthController#callback に入りました"
    state_cookie = cookies[:oauth_state]
    # 成否によらず冒頭で削除する。残すと同じ認可コードを再送されうる
    clear_oauth_state_cookie

    result = Oauth::CallbackService.call(
      provider: params[:provider],
      code: params[:code],
      state: params[:state],
      error: params[:error],
      state_cookie: state_cookie
    )

    case result[:status]
    when :logged_in
      set_refresh_token_cookie(result[:refresh_token], expires_at: result[:refresh_token_expires_at])
      redirect_to frontend_url(HOME_PATH), allow_other_host: true
    when :signup_required
      set_signup_token_cookie(result[:signup_token])
      redirect_to frontend_url(SIGNUP_PATH), allow_other_host: true
    else
      redirect_to frontend_url(LOGIN_PATH, error: result[:error_code]), allow_other_host: true
    end
  end

  private

  # 遷移先は環境変数で固定する。params 由来の値を混ぜるとオープンリダイレクトになる
  def frontend_url(path, query = {})
    url = "#{ENV.fetch('FRONTEND_URL')}#{path}"
    query.present? ? "#{url}?#{query.to_query}" : url
  end
end

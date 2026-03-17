module V1
  module Auth
    class SessionsController < V1::BaseController
      # ActionController::API はデフォルトで Cookie を扱えないため明示的にインクルードする
      include ActionController::Cookies

      def login
        Rails.logger.debug "SessionsController#login に入りました"
        result = ::Auth::LoginService.call(
          clerk_token: clerk_token_from_header
        )

        # httponly: JSからアクセス不可にしてXSS対策、secure: HTTPS限定、same_site: laxでCSRF対策しつつ通常のリンク遷移は許容
        response.set_cookie(
          :refresh_token,
          value: result[:refresh_token],
          httponly: true,
          secure: true,
          same_site: :lax,
          domain: Rails.application.config.cookie_domain,
          expires: TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now
        )

        render json: { access_token: result[:access_token] }, status: :ok
      end

      def logout
        Rails.logger.debug "SessionsController#logout に入りました"
        result = ::Auth::LogoutService.call(refresh_token: cookies[:refresh_token])

        # DBレコードの有無に関わらず、残存する Cookie を確実に破棄する
        response.delete_cookie(
          :refresh_token,
          domain: Rails.application.config.cookie_domain
        )

        if result == :logged_out
          render json: { message: I18n.t("messages.auth.logout.logged_out") }, status: :ok
        else
          render json: { message: I18n.t("messages.auth.logout.already_logged_out") }, status: :ok
        end
      end
    end
  end
end

module V1
  module Auth
    class SessionsController < V1::BaseController
      include RefreshTokenCookie

      def login
        Rails.logger.debug "SessionsController#login に入りました"
        result = ::Auth::LoginService.call(
          clerk_token: clerk_token_from_header
        )

        set_refresh_token_cookie(result[:refresh_token], expires_at: result[:refresh_token_expires_at])

        render json: { access_token: result[:access_token] }, status: :ok
      end

      def refresh
        Rails.logger.debug "SessionsController#refresh に入りました"
        result = ::Auth::RefreshService.call(refresh_token: cookies[:refresh_token])

        if result[:new_refresh_token]
          set_refresh_token_cookie(result[:new_refresh_token], expires_at: result[:new_refresh_token_expires_at])
        end

        render json: { access_token: result[:access_token] }, status: :ok
      end

      def logout
        Rails.logger.debug "SessionsController#logout に入りました"
        result = ::Auth::LogoutService.call(refresh_token: cookies[:refresh_token])

        # DBレコードの有無に関わらず、残存する Cookie を確実に破棄する
        clear_refresh_token_cookie

        if result == :logged_out
          render json: { message: I18n.t("messages.auth.logout.logged_out") }, status: :ok
        else
          render json: { message: I18n.t("messages.auth.logout.already_logged_out") }, status: :ok
        end
      end
    end
  end
end

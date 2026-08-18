module Oauth
  # コールバックの分岐の中心。プロバイダ名で分岐しないこと（差は lib/oauth/providers に閉じている）。
  #
  # 失敗を例外で返さないのは、コールバックがブラウザのトップレベル遷移だからである。
  # ErrorHandler に流すと生の JSON がページとして表示されてしまうため、
  # ここですべての失敗をエラーコードに畳み、呼び出し側はリダイレクトだけを行う。
  class CallbackService
    ERROR_CANCELLED                = "cancelled".freeze
    ERROR_INVALID_STATE            = "invalid_state".freeze
    ERROR_PROVIDER                 = "provider_error".freeze
    ERROR_EMAIL_UNAVAILABLE        = "email_unavailable".freeze
    ERROR_EMAIL_ALREADY_REGISTERED = "email_already_registered".freeze

    class << self
      def call(provider:, code:, state:, error:, state_cookie:)
        # 同意画面でキャンセルされた場合、IdP は code ではなく error を付けて戻す
        if error.present?
          Rails.logger.info "コールバック中断: 同意画面でキャンセル provider=#{provider}"
          return failure(ERROR_CANCELLED)
        end

        payload = State.decode(state_cookie)
        unless valid_request?(payload: payload, state: state, provider: provider, code: code)
          # ErrorHandler を通さない経路なので、ここで出さないと CSRF 疑いが記録に残らない
          Rails.logger.warn "コールバック失敗: state 検証に失敗 provider=#{provider}"
          return failure(ERROR_INVALID_STATE)
        end

        identity = Providers.fetch(provider).fetch_identity(code: code, code_verifier: payload["code_verifier"])
        resolve(identity)
      rescue EmailUnavailableError => e
        Rails.logger.warn "コールバック失敗: メールを取得できません #{e.message}"
        failure(ERROR_EMAIL_UNAVAILABLE)
      rescue ProviderError, UnsupportedProviderError => e
        Rails.logger.warn "コールバック失敗: プロバイダ起因 #{e.class} #{e.message}"
        failure(ERROR_PROVIDER)
      rescue StandardError => e
        # 想定外の例外もリダイレクトで返しきる。ここで漏らすと JSON が表示される
        Rails.logger.error "コールバック失敗: 想定外の例外 #{e.class} #{e.message}"
        failure(ERROR_PROVIDER)
      end

      private

      def valid_request?(payload:, state:, provider:, code:)
        return false if payload.blank?
        # 長さの違いで早期リターンしないよう、固定時間比較で state を照合する
        return false unless ActiveSupport::SecurityUtils.secure_compare(payload["state"].to_s, state.to_s)
        # Cookie を別プロバイダの認可レスポンスに使い回されるのを防ぐ
        return false unless payload["provider"] == provider

        code.present?
      end

      # user_identities に (provider, provider_uid) があればログイン、無ければサインアップ。
      def resolve(identity)
        user_identity = UserIdentity.find_by(provider: identity.provider, provider_uid: identity.uid)
        return login(user_identity.user) if user_identity

        # 同一メールの既存ユーザーがいても自動では紐付けない。
        # IdP のメールを信じて既存アカウントを乗っ取れてしまうため、複数連携は別途 UI で行う
        if User.exists?(email: identity.email)
          Rails.logger.warn "コールバック失敗: メールが別アカウントで登録済み provider=#{identity.provider}"
          return failure(ERROR_EMAIL_ALREADY_REGISTERED)
        end

        Rails.logger.info "サインアップ導線へ遷移: provider=#{identity.provider}"
        { status: :signup_required, signup_token: TokenIssuer.issue_signup_token(identity) }
      end

      def login(user)
        refresh_token            = TokenIssuer.issue_refresh_token(user)
        refresh_token_expires_at = TokenIssuer::REFRESH_TOKEN_EXPIRY.from_now

        # リフレッシュトークンはDBで管理し、失効・ローテーションを可能にする
        RefreshToken.create!(user: user, token: refresh_token, expires_at: refresh_token_expires_at)

        Rails.logger.info "ログイン成功: user_id=#{user.id}"
        {
          status: :logged_in,
          refresh_token: refresh_token,
          refresh_token_expires_at: refresh_token_expires_at
        }
      end

      def failure(error_code)
        { status: :failed, error_code: error_code }
      end
    end
  end
end

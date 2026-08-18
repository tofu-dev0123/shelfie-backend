require "rails_helper"

RSpec.describe Oauth::CallbackService, type: :service do
  let(:provider) { "google" }
  let(:identity) do
    Oauth::Identity.new(provider: provider, uid: "uid_123", email: "komu@example.com", name: "コムサン")
  end

  # State.issue の戻り値をそのまま使い、Cookie と state が揃った正常な往復を作る
  let(:issued)       { Oauth::State.issue(provider: provider) }
  let(:state_cookie) { issued[0] }
  let(:state)        { issued[1] }

  before do
    allow(Oauth::Providers::Google).to receive(:fetch_identity).and_return(identity)
  end

  def call(overrides = {})
    described_class.call(**{
      provider: provider, code: "auth_code", state: state, error: nil, state_cookie: state_cookie
    }.merge(overrides))
  end

  describe ".call" do
    context "user_identities にヒットする既存ユーザーの場合" do
      let!(:user_identity) { create(:user_identity, provider: provider, provider_uid: identity.uid) }

      it "ログインとしてリフレッシュトークンを発行する" do
        result = call

        expect(result[:status]).to eq(:logged_in)
        expect(result[:refresh_token]).to be_present
        expect(result[:refresh_token_expires_at]).to be_present
      end

      it "RefreshToken レコードを作成する" do
        expect { call }.to change(RefreshToken, :count).by(1)
        expect(RefreshToken.last.user_id).to eq(user_identity.user_id)
      end
    end

    context "user_identities にヒットしない新規ユーザーの場合" do
      it "signup_token を返す" do
        result = call

        expect(result[:status]).to eq(:signup_required)
        payload = TokenIssuer.decode_signup_token(result[:signup_token])
        expect(payload["provider"]).to eq(provider)
        expect(payload["uid"]).to      eq(identity.uid)
        expect(payload["email"]).to    eq(identity.email)
      end

      it "User を作らない（作成は POST /v1/users の担当）" do
        expect { call }.not_to change(User, :count)
      end
    end

    context "state が Cookie の値と一致しない場合" do
      it "invalid_state で離脱する" do
        result = call(state: "tampered_state")

        expect(result[:status]).to     eq(:failed)
        expect(result[:error_code]).to eq(described_class::ERROR_INVALID_STATE)
      end
    end

    context "oauth_state Cookie が無い場合" do
      it "invalid_state で離脱する" do
        result = call(state_cookie: nil)

        expect(result[:status]).to     eq(:failed)
        expect(result[:error_code]).to eq(described_class::ERROR_INVALID_STATE)
      end
    end

    context "Cookie の provider と URL の provider が食い違う場合" do
      it "invalid_state で離脱する" do
        result = call(provider: "github")

        expect(result[:status]).to     eq(:failed)
        expect(result[:error_code]).to eq(described_class::ERROR_INVALID_STATE)
      end
    end

    context "同一メールの既存ユーザーがいる場合" do
      before { create(:user, email: identity.email) }

      it "email_already_registered で離脱し、自動で紐付けない" do
        result = call

        expect(result[:status]).to     eq(:failed)
        expect(result[:error_code]).to eq(described_class::ERROR_EMAIL_ALREADY_REGISTERED)
        expect(UserIdentity.count).to  eq(0)
      end
    end

    context "IdP がキャンセルを返した場合" do
      it "cancelled で離脱する" do
        result = call(error: "access_denied")

        expect(result[:status]).to     eq(:failed)
        expect(result[:error_code]).to eq(described_class::ERROR_CANCELLED)
      end
    end

    context "code が空の場合" do
      it "invalid_state で離脱する" do
        result = call(code: nil)

        expect(result[:status]).to     eq(:failed)
        expect(result[:error_code]).to eq(described_class::ERROR_INVALID_STATE)
      end
    end

    context "トークン交換が失敗した場合" do
      it "provider_error で離脱する" do
        allow(Oauth::Providers::Google).to receive(:fetch_identity).and_raise(Oauth::ProviderError)

        result = call

        expect(result[:status]).to     eq(:failed)
        expect(result[:error_code]).to eq(described_class::ERROR_PROVIDER)
      end
    end

    context "verified なメールを取得できなかった場合" do
      it "email_unavailable で離脱する" do
        allow(Oauth::Providers::Google).to receive(:fetch_identity).and_raise(Oauth::EmailUnavailableError)

        result = call

        expect(result[:status]).to     eq(:failed)
        expect(result[:error_code]).to eq(described_class::ERROR_EMAIL_UNAVAILABLE)
      end
    end
  end
end

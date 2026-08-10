require "rails_helper"

RSpec.describe Auth::SignupContextService, type: :service do
  let(:identity) do
    Oauth::Identity.new(provider: "google", uid: "uid_123", email: "komu@example.com", name: "コムサン")
  end

  describe ".call" do
    context "正常系" do
      it "email と nickname_suggestion を返す" do
        result = described_class.call(signup_token: TokenIssuer.issue_signup_token(identity))

        expect(result[:email]).to               eq("komu@example.com")
        expect(result[:nickname_suggestion]).to eq("コムサン")
      end

      it "name クレームが null のとき nickname_suggestion は空文字になる" do
        token = TokenIssuer.issue_signup_token(
          Oauth::Identity.new(provider: "github", uid: "uid_456", email: "komu@example.com", name: nil)
        )

        expect(described_class.call(signup_token: token)[:nickname_suggestion]).to eq("")
      end
    end

    context "異常系" do
      it "Cookie が無いとき UnauthorizedError を raise する" do
        expect { described_class.call(signup_token: nil) }.to raise_error(UnauthorizedError)
      end

      it "purpose が signup でないとき UnauthorizedError を raise する" do
        access_token = TokenIssuer.issue_access_token(create(:user))

        expect { described_class.call(signup_token: access_token) }.to raise_error(UnauthorizedError)
      end
    end
  end
end

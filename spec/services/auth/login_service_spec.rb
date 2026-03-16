require "rails_helper"

RSpec.describe Auth::LoginService, type: :service do
  let(:clerk_token) { "valid_clerk_token" }
  let!(:user) { create(:user, clerk_user_id: "clerk_abc123") }
  let(:clerk_payload) { { clerk_user_id: "clerk_abc123", email: user.email } }

  before do
    allow(ClerkClient).to receive(:verify).with(clerk_token).and_return(clerk_payload)
  end

  describe ".call" do
    context "正常系" do
      it "RefreshToken レコードが作成される" do
        expect { described_class.call(clerk_token: clerk_token) }.to change(RefreshToken, :count).by(1)
      end

      it "access_token と refresh_token を返す" do
        result = described_class.call(clerk_token: clerk_token)
        expect(result[:access_token]).to be_present
        expect(result[:refresh_token]).to be_present
      end
    end

    context "異常系" do
      it "Clerk JWT が無効のとき ClerkClient::UnauthorizedError を raise する" do
        allow(ClerkClient).to receive(:verify).and_raise(ClerkClient::UnauthorizedError)
        expect { described_class.call(clerk_token: clerk_token) }.to raise_error(ClerkClient::UnauthorizedError)
      end

      it "ユーザーが存在しないとき UserNotFoundError を raise する" do
        allow(ClerkClient).to receive(:verify).and_return({ clerk_user_id: "clerk_not_registered", email: "unknown@example.com" })
        expect { described_class.call(clerk_token: clerk_token) }.to raise_error(UserNotFoundError)
      end
    end
  end
end

require "rails_helper"

RSpec.describe Users::CreateService, type: :service do
  let(:clerk_token) { "valid_clerk_token" }
  let(:clerk_payload) { { clerk_user_id: "clerk_abc123", email: "komu@example.com" } }
  let(:valid_params) do
    { clerk_token: clerk_token, nickname: "コムさん", username: "komusan" }
  end

  before do
    allow(ClerkClient).to receive(:verify).with(clerk_token).and_return(clerk_payload)
  end

  describe ".call" do
    context "正常系" do
      it "User レコードが作成される" do
        expect { described_class.call(**valid_params) }.to change(User, :count).by(1)
      end

      it "username が小文字に正規化されて保存される" do
        described_class.call(**valid_params.merge(username: "KomuSan"))
        expect(User.last.username).to eq("komusan")
      end

      it "RefreshToken レコードが作成される" do
        expect { described_class.call(**valid_params) }.to change(RefreshToken, :count).by(1)
      end

      it "access_token と refresh_token を返す" do
        result = described_class.call(**valid_params)
        expect(result[:access_token]).to be_present
        expect(result[:refresh_token]).to be_present
      end
    end

    context "異常系" do
      it "Clerk JWT が無効のとき ClerkClient::UnauthorizedError を raise する" do
        allow(ClerkClient).to receive(:verify).and_raise(ClerkClient::UnauthorizedError)
        expect { described_class.call(**valid_params) }.to raise_error(ClerkClient::UnauthorizedError)
      end

      it "clerk_user_id が重複のとき AccountAlreadyExistsError を raise する" do
        create(:user, clerk_user_id: "clerk_abc123")
        expect { described_class.call(**valid_params) }.to raise_error(AccountAlreadyExistsError)
      end

      it "username が重複のとき UsernameTakenError を raise する" do
        create(:user, username: "komusan")
        expect { described_class.call(**valid_params) }.to raise_error(UsernameTakenError)
      end

      it "nickname が空のとき ActiveRecord::RecordInvalid を raise する" do
        expect { described_class.call(**valid_params.merge(nickname: "")) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it "username が3文字以下のとき ActiveRecord::RecordInvalid を raise する" do
        expect { described_class.call(**valid_params.merge(username: "ab")) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

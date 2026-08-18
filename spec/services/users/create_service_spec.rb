require "rails_helper"

RSpec.describe Users::CreateService, type: :service do
  let(:identity) do
    Oauth::Identity.new(provider: "google", uid: "uid_123", email: "komu@example.com", name: "コムサン")
  end
  let(:signup_token) { TokenIssuer.issue_signup_token(identity) }
  let(:valid_params) do
    { signup_token: signup_token, nickname: "コムさん", username: "komusan" }
  end

  describe ".call" do
    context "正常系" do
      it "User レコードが作成される" do
        expect { described_class.call(**valid_params) }.to change(User, :count).by(1)
      end

      it "UserIdentity レコードが signup_token の provider / uid で作成される" do
        expect { described_class.call(**valid_params) }.to change(UserIdentity, :count).by(1)

        expect(UserIdentity.last.provider).to     eq("google")
        expect(UserIdentity.last.provider_uid).to eq("uid_123")
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
      it "signup_token が無効のとき UnauthorizedError を raise する" do
        expect { described_class.call(**valid_params.merge(signup_token: "invalid")) }
          .to raise_error(UnauthorizedError)
      end

      it "signup_token が無いとき UnauthorizedError を raise する" do
        expect { described_class.call(**valid_params.merge(signup_token: nil)) }
          .to raise_error(UnauthorizedError)
      end

      it "アクセストークンを signup_token として渡したとき UnauthorizedError を raise する" do
        access_token = TokenIssuer.issue_access_token(create(:user))

        expect { described_class.call(**valid_params.merge(signup_token: access_token)) }
          .to raise_error(UnauthorizedError)
      end

      it "(provider, provider_uid) が重複のとき AccountAlreadyExistsError を raise する" do
        create(:user_identity, provider: "google", provider_uid: "uid_123")

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

      it "作成に失敗したとき User も UserIdentity も残らない" do
        expect { described_class.call(**valid_params.merge(nickname: "")) }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(User.count).to         eq(0)
        expect(UserIdentity.count).to eq(0)
      end
    end
  end
end

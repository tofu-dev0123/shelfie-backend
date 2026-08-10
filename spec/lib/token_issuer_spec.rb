require "rails_helper"

RSpec.describe TokenIssuer do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:identity) do
    Oauth::Identity.new(provider: "google", uid: "uid_123", email: "komu@example.com", name: "コムサン")
  end

  describe ".issue_signup_token と .decode_signup_token" do
    it "provider / uid / email / name を復元できる" do
      payload = described_class.decode_signup_token(described_class.issue_signup_token(identity))

      expect(payload["purpose"]).to  eq("signup")
      expect(payload["provider"]).to eq("google")
      expect(payload["uid"]).to      eq("uid_123")
      expect(payload["email"]).to    eq("komu@example.com")
      expect(payload["name"]).to     eq("コムサン")
    end

    it "10分を超えて期限切れになったトークンのとき nil を返す" do
      token = described_class.issue_signup_token(identity)

      travel_to(described_class::SIGNUP_TOKEN_EXPIRY.from_now + 1.second) do
        expect(described_class.decode_signup_token(token)).to be_nil
      end
    end

    it "アクセストークンを渡すと nil を返す" do
      expect(described_class.decode_signup_token(described_class.issue_access_token(user))).to be_nil
    end
  end

  describe ".decode" do
    context "アクセストークンを purpose: \"access\" で検証した場合" do
      it "payload を返す" do
        token = described_class.issue_access_token(user)

        payload = described_class.decode(token, purpose: "access")

        expect(payload["user_id"]).to eq(user.id)
        expect(payload["purpose"]).to eq("access")
      end
    end

    context "リフレッシュトークンを purpose: \"refresh\" で検証した場合" do
      it "payload を返す" do
        token = described_class.issue_refresh_token(user)

        payload = described_class.decode(token, purpose: "refresh")

        expect(payload["user_id"]).to eq(user.id)
        expect(payload["purpose"]).to eq("refresh")
      end
    end

    context "リフレッシュトークンを purpose: \"access\" で検証した場合" do
      it "nil を返す" do
        token = described_class.issue_refresh_token(user)

        expect(described_class.decode(token, purpose: "access")).to be_nil
      end
    end

    context "サインアップトークンを purpose: \"access\" で検証した場合" do
      it "nil を返す" do
        token = described_class.issue_signup_token(identity)

        expect(described_class.decode(token, purpose: "access")).to be_nil
      end
    end

    context "アクセストークンを purpose: \"signup\" で検証した場合" do
      it "nil を返す" do
        token = described_class.issue_access_token(user)

        expect(described_class.decode(token, purpose: "signup")).to be_nil
      end
    end

    context "署名を改竄したトークンの場合" do
      it "nil を返す" do
        token = described_class.issue_access_token(user)
        tampered_token = "#{token[0..-2]}#{token[-1] == 'a' ? 'b' : 'a'}"

        expect(described_class.decode(tampered_token, purpose: "access")).to be_nil
      end
    end

    context "purpose を渡さずに呼んだ場合" do
      it "ArgumentError が発生する" do
        token = described_class.issue_access_token(user)

        expect { described_class.decode(token) }.to raise_error(ArgumentError)
      end
    end
  end
end

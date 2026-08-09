require "rails_helper"

RSpec.describe TokenIssuer do
  let(:user) { create(:user) }

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

require "rails_helper"

RSpec.describe Oauth::State do
  include ActiveSupport::Testing::TimeHelpers

  describe ".issue と .decode" do
    context "正常系" do
      it "issue した Cookie 値を decode すると state / code_verifier / provider が復元される" do
        cookie, state, = described_class.issue(provider: "google")

        payload = described_class.decode(cookie)

        expect(payload["state"]).to eq(state)
        expect(payload["provider"]).to eq("google")
        expect(payload["code_verifier"]).to be_present
      end

      it "code_challenge が BASE64URL(SHA256(code_verifier)) と一致する" do
        cookie, _state, code_challenge = described_class.issue(provider: "google")

        code_verifier = described_class.decode(cookie)["code_verifier"]

        expect(code_challenge).to eq(
          Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
        )
      end
    end

    context "異常系" do
      it "署名を改竄した Cookie 値のとき nil を返す" do
        cookie, = described_class.issue(provider: "google")
        tampered = "#{cookie[0..-2]}#{cookie[-1] == 'a' ? 'b' : 'a'}"

        expect(described_class.decode(tampered)).to be_nil
      end

      it "10分を超えて期限切れになった Cookie 値のとき nil を返す" do
        cookie, = described_class.issue(provider: "google")

        travel_to(described_class::EXPIRY.from_now + 1.second) do
          expect(described_class.decode(cookie)).to be_nil
        end
      end

      it "purpose が oauth_state 以外の JWT のとき nil を返す" do
        payload = {
          purpose: "signup", provider: "google", state: "s", code_verifier: "v",
          exp: 10.minutes.from_now.to_i
        }
        cookie = JWT.encode(payload, Rails.application.secret_key_base, "HS256")

        expect(described_class.decode(cookie)).to be_nil
      end

      it "Cookie が無いとき nil を返す" do
        expect(described_class.decode(nil)).to be_nil
      end
    end
  end
end

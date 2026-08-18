require "rails_helper"

RSpec.describe Oauth::Providers::Google do
  let(:client_id) { "google-client-id.apps.googleusercontent.com" }

  let(:claims) do
    {
      iss:            "https://accounts.google.com",
      aud:            client_id,
      sub:            "108512345678901234567",
      email:          "user@example.com",
      email_verified: true,
      name:           "コムサン",
      exp:            10.minutes.from_now.to_i
    }
  end

  # ENV.fetch を使っているため、未設定だと KeyError になる。
  # CI にはダミー値を置いているが、spec 側でも明示して実行環境に依存させない。
  around do |example|
    original = ENV.to_h
    ENV["GOOGLE_OAUTH_CLIENT_ID"]     = client_id
    ENV["GOOGLE_OAUTH_CLIENT_SECRET"] = "google-client-secret"
    ENV["API_BASE_URL"]               = "https://api.example.com"
    example.run
  ensure
    ENV.replace(original)
  end

  # id_token は token endpoint から TLS 越しに直接受領するため署名検証をしない。
  # 実装が JWT.decode(..., false) で読む前提なので、鍵は何でもよい。
  def id_token(overrides = {})
    JWT.encode(claims.merge(overrides), "signed-by-google", "HS256")
  end

  def stub_token_endpoint(body:, status: 200)
    stub_request(:post, described_class::TOKEN_ENDPOINT)
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe ".fetch_identity" do
    subject(:fetch_identity) { described_class.fetch_identity(code: "auth_code", code_verifier: "verifier") }

    context "正常系" do
      it "Identity を返す" do
        stub_token_endpoint(body: { id_token: id_token })

        expect(fetch_identity).to eq(
          Oauth::Identity.new(provider: "google", uid: claims[:sub], email: claims[:email], name: claims[:name])
        )
      end
    end

    context "異常系" do
      it "iss が不正のとき ProviderError を raise する" do
        stub_token_endpoint(body: { id_token: id_token(iss: "https://evil.example.com") })

        expect { fetch_identity }.to raise_error(Oauth::ProviderError)
      end

      it "aud が GOOGLE_OAUTH_CLIENT_ID と一致しないとき ProviderError を raise する" do
        stub_token_endpoint(body: { id_token: id_token(aud: "other-app.apps.googleusercontent.com") })

        expect { fetch_identity }.to raise_error(Oauth::ProviderError)
      end

      it "exp が過去のとき ProviderError を raise する" do
        stub_token_endpoint(body: { id_token: id_token(exp: 1.minute.ago.to_i) })

        expect { fetch_identity }.to raise_error(Oauth::ProviderError)
      end

      it "email_verified が false のとき ProviderError を raise する" do
        stub_token_endpoint(body: { id_token: id_token(email_verified: false) })

        expect { fetch_identity }.to raise_error(Oauth::ProviderError)
      end

      it "トークンエンドポイントが 4xx を返すとき ProviderError を raise する" do
        stub_token_endpoint(body: { error: "invalid_grant" }, status: 400)

        expect { fetch_identity }.to raise_error(Oauth::ProviderError)
      end
    end
  end
end

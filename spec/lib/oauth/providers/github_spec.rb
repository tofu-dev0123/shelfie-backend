require "rails_helper"

RSpec.describe Oauth::Providers::Github do
  let(:user_response) { { id: 12_345_678, login: "komu", name: "コムサン" } }
  let(:emails_response) do
    [
      { email: "secondary@example.com", primary: false, verified: true },
      { email: "user@example.com",      primary: true,  verified: true }
    ]
  end

  # ENV.fetch を使っているため、未設定だと KeyError になる。
  # CI にはダミー値を置いているが、spec 側でも明示して実行環境に依存させない。
  around do |example|
    original = ENV.to_h
    ENV["GITHUB_OAUTH_CLIENT_ID"]     = "github-client-id"
    ENV["GITHUB_OAUTH_CLIENT_SECRET"] = "github-client-secret"
    ENV["API_BASE_URL"]               = "https://api.example.com"
    example.run
  ensure
    ENV.replace(original)
  end

  def stub_token_endpoint(body: { access_token: "gho_dummy" }, status: 200)
    stub_request(:post, described_class::TOKEN_ENDPOINT)
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_user(body: nil)
    stub_request(:get, "#{described_class::API_BASE}/user")
      .to_return(status: 200, body: (body || user_response).to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  def stub_emails(body: nil)
    stub_request(:get, "#{described_class::API_BASE}/user/emails")
      .to_return(status: 200, body: (body || emails_response).to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  describe ".fetch_identity" do
    subject(:fetch_identity) { described_class.fetch_identity(code: "auth_code", code_verifier: "verifier") }

    context "正常系" do
      before do
        stub_token_endpoint
        stub_user
        stub_emails
      end

      it "Identity を返し、uid が String である" do
        identity = fetch_identity

        expect(identity).to eq(
          Oauth::Identity.new(provider: "github", uid: "12345678", email: "user@example.com", name: "コムサン")
        )
        expect(identity.uid).to be_a(String)
      end

      context "user.name が null の場合" do
        it "login が name に入る" do
          stub_user(body: user_response.merge(name: nil))

          expect(fetch_identity.name).to eq("komu")
        end
      end
    end

    context "異常系" do
      it "primary かつ verified のメールが無いとき EmailUnavailableError を raise する" do
        stub_token_endpoint
        stub_user
        stub_emails(body: [ { email: "user@example.com", primary: true, verified: false } ])

        expect { fetch_identity }.to raise_error(Oauth::EmailUnavailableError)
      end

      it "HTTP 200 かつ body が { error: ... } のとき ProviderError を raise する" do
        stub_token_endpoint(body: { error: "bad_verification_code" })

        expect { fetch_identity }.to raise_error(Oauth::ProviderError)
      end

      it "トークンエンドポイントが 4xx を返すとき ProviderError を raise する" do
        stub_token_endpoint(body: { error: "incorrect_client_credentials" }, status: 401)

        expect { fetch_identity }.to raise_error(Oauth::ProviderError)
      end
    end
  end
end

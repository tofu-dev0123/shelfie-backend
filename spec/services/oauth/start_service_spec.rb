require "rails_helper"

RSpec.describe Oauth::StartService, type: :service do
  # プロバイダ層は ENV.fetch を使っているため、未設定だと KeyError になる。
  # CI にはダミー値を置いているが、spec 側でも明示して実行環境に依存させない。
  around do |example|
    original = ENV.to_h
    ENV["GOOGLE_OAUTH_CLIENT_ID"]     = "google-client-id"
    ENV["GOOGLE_OAUTH_CLIENT_SECRET"] = "google-client-secret"
    ENV["API_BASE_URL"]               = "https://api.example.com"
    example.run
  ensure
    ENV.replace(original)
  end

  describe ".call" do
    context "正常系" do
      it "認可 URL と state Cookie を返す" do
        result = described_class.call(provider: "google")

        expect(result[:authorize_url]).to start_with(Oauth::Providers::Google::AUTHORIZE_ENDPOINT)
        expect(Oauth::State.decode(result[:state_cookie])["provider"]).to eq("google")
      end

      it "認可 URL の state が Cookie の state と一致する" do
        result = described_class.call(provider: "google")

        query = Rack::Utils.parse_query(URI(result[:authorize_url]).query)
        expect(query["state"]).to eq(Oauth::State.decode(result[:state_cookie])["state"])
      end

      it "intent の指定がないとき auth を既定にする" do
        result = described_class.call(provider: "google")

        expect(Oauth::State.decode(result[:state_cookie])["intent"]).to eq(described_class::DEFAULT_INTENT)
      end
    end

    context "異常系" do
      it "未対応の provider のとき UnsupportedProviderError を raise する" do
        expect { described_class.call(provider: "facebook") }
          .to raise_error(Oauth::UnsupportedProviderError)
      end
    end
  end
end

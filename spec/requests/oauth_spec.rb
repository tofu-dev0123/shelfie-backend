require "rails_helper"

RSpec.describe "OAuth", type: :request do
  let(:frontend_url) { "https://app.example.com" }
  let(:identity) do
    Oauth::Identity.new(provider: "google", uid: "uid_123", email: "komu@example.com", name: "コムサン")
  end

  # プロバイダ層は ENV.fetch を使っているため、未設定だと KeyError になる。
  # CI にはダミー値を置いているが、spec 側でも明示して実行環境に依存させない。
  around do |example|
    original = ENV.to_h
    ENV["GOOGLE_OAUTH_CLIENT_ID"]     = "google-client-id"
    ENV["GOOGLE_OAUTH_CLIENT_SECRET"] = "google-client-secret"
    ENV["GITHUB_OAUTH_CLIENT_ID"]     = "github-client-id"
    ENV["GITHUB_OAUTH_CLIENT_SECRET"] = "github-client-secret"
    ENV["API_BASE_URL"]               = "https://api.example.com"
    ENV["FRONTEND_URL"]               = frontend_url
    example.run
  ensure
    ENV.replace(original)
  end

  # Rack 3 では Set-Cookie が配列になりうるため、まとめて1つの文字列として検証する
  def set_cookie_header
    Array(response.headers["Set-Cookie"]).join("\n")
  end

  def get_callback(provider: "google", state_cookie: nil, **query)
    headers = state_cookie ? { "Cookie" => "oauth_state=#{state_cookie}" } : {}
    get "/auth/#{provider}/callback", params: query, headers: headers
  end

  describe "GET /auth/:provider" do
    it "Google の認可エンドポイントへ 302 する" do
      get "/auth/google"

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to start_with(Oauth::Providers::Google::AUTHORIZE_ENDPOINT)
    end

    it "state / code_challenge / code_challenge_method=S256 を含む" do
      get "/auth/google"

      query = Rack::Utils.parse_query(URI(response.headers["Location"]).query)
      expect(query["state"]).to be_present
      expect(query["code_challenge"]).to be_present
      expect(query["code_challenge_method"]).to eq("S256")
    end

    it "oauth_state Cookie を Path=/auth・HttpOnly でセットする" do
      get "/auth/google"

      expect(set_cookie_header).to match(/oauth_state=/i)
      expect(set_cookie_header).to match(/path=\/auth/i)
      expect(set_cookie_header).to match(/httponly/i)
    end

    it "GitHub でも認可エンドポイントへ 302 する" do
      get "/auth/github"

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to start_with(Oauth::Providers::Github::AUTHORIZE_ENDPOINT)
    end

    it "許可していない provider は 404 を返す" do
      get "/auth/facebook"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /auth/:provider/callback" do
    let(:issued)       { Oauth::State.issue(provider: "google") }
    let(:state_cookie) { issued[0] }
    let(:state)        { issued[1] }

    before do
      allow(Oauth::Providers::Google).to receive(:fetch_identity).and_return(identity)
    end

    context "既存ユーザーの場合" do
      before { create(:user_identity, provider: "google", provider_uid: identity.uid) }

      it "フロントのトップへ 302 し、refresh_token Cookie をセットする" do
        get_callback(state_cookie: state_cookie, code: "auth_code", state: state)

        expect(response).to redirect_to("#{frontend_url}/")
        expect(set_cookie_header).to match(/refresh_token=/i)
      end
    end

    context "新規ユーザーの場合" do
      it "サインアップ画面へ 302 し、signup_token Cookie をセットする" do
        get_callback(state_cookie: state_cookie, code: "auth_code", state: state)

        expect(response).to redirect_to("#{frontend_url}/signup")
        expect(set_cookie_header).to match(/signup_token=/i)
      end
    end

    context "IdP がキャンセルを返した場合" do
      it "error=cancelled でログイン画面へ戻す" do
        get_callback(state_cookie: state_cookie, error: "access_denied")

        expect(response).to redirect_to("#{frontend_url}/login?error=cancelled")
      end
    end

    context "state が不正な場合" do
      it "error=invalid_state でログイン画面へ戻す" do
        get_callback(state_cookie: state_cookie, code: "auth_code", state: "tampered")

        expect(response).to redirect_to("#{frontend_url}/login?error=invalid_state")
      end
    end

    # 認可コードのリプレイを防ぐため、どの経路でも Cookie を消し切る必要がある
    context "どの経路でも" do
      it "成功時に oauth_state Cookie を削除する" do
        get_callback(state_cookie: state_cookie, code: "auth_code", state: state)

        expect(set_cookie_header).to match(/oauth_state=;/i)
      end

      it "失敗時に oauth_state Cookie を削除する" do
        get_callback(state_cookie: state_cookie, code: "auth_code", state: "tampered")

        expect(set_cookie_header).to match(/oauth_state=;/i)
      end

      it "Cookie が無いときも oauth_state Cookie の削除を返す" do
        get_callback(code: "auth_code", state: state)

        expect(response).to redirect_to("#{frontend_url}/login?error=invalid_state")
        expect(set_cookie_header).to match(/oauth_state=;/i)
      end
    end
  end
end

# テスト

## 基本ルール

- **spec を先に書く**（TDD：実装前に spec を書く）
- **`described_class` を使う**（クラス名をハードコードしない）
- **外部APIは必ずモックする**（OAuth プロバイダ・楽天書籍APIを実際に叩かない）

## 構成

```
spec/
├── rails_helper.rb        # RailsとRSpecの統合設定
├── spec_helper.rb         # RSpec本体の設定
├── swagger_helper.rb      # rswag設定（Request specで require する）
├── factories/             # FactoryBot（テストデータのひな形）
│   ├── users.rb
│   ├── user_identities.rb
│   ├── books.rb
│   └── user_books.rb
├── models/                # Modelのバリデーションテスト
│   └── user_spec.rb
├── lib/                   # lib/ のユニットテスト
│   └── oauth/
│       ├── state_spec.rb
│       └── providers/     # プロバイダごとの本人情報取り出し
├── services/              # Serviceのビジネスロジックテスト
│   ├── oauth/
│   │   └── callback_service_spec.rb
│   └── users/
│       └── create_service_spec.rb
└── requests/              # APIエンドポイントテスト
    ├── oauth_spec.rb      # /v1 外（リダイレクト系）
    └── v1/
        └── users_spec.rb
```

`GET /auth/:provider` 系は JSON を返さないため rswag ではなく通常の request spec で書く。
検証するのは**リダイレクト先と Set-Cookie** である。

## テスト用DB

ローカルのPostgreSQLサーバー上に `shelfie_test` DBを使用する。rspec実行時に自動接続される。

```bash
# 初回セットアップ
rails db:create         # shelfie_development と shelfie_test を作成
rails db:test:prepare   # テスト用DBにマイグレーションを適用
```

テストケースごとにトランザクションをロールバックするため、テスト間でデータは汚染されない。

```ruby
# spec/rails_helper.rb
config.use_transactional_fixtures = true
```

## FactoryBot

テストデータのひな形を定義する。

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    username { "komu" }
    nickname { "コムサン" }
  end
end
```

```ruby
create(:user)                    # DBに保存（Request・Service spec向け）
create(:user, username: "other") # 一部上書き
build(:user)                     # DBに保存しない（Model spec向け）
```

## Model spec

バリデーションルールを全パターン網羅する。

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe "バリデーション" do
    context "正常系" do
      it "全項目が正しければ有効" do
        expect(build(:user)).to be_valid
      end
    end

    context "username" do
      it "空のとき無効" do
        expect(build(:user, username: "")).not_to be_valid
      end

      it "重複のとき無効" do
        create(:user, username: "komu")
        expect(build(:user, username: "komu")).not_to be_valid
      end

      it "半角英数字・アンダースコア以外のとき無効" do
        expect(build(:user, username: "コム")).not_to be_valid
      end
    end
  end
end
```

## Service spec

正常系と異常系を書く。外部APIはスタブで偽レスポンスを返す。

```ruby
# spec/services/users/create_service_spec.rb
RSpec.describe Users::CreateService, type: :service do
  let(:identity) do
    Oauth::Identity.new(provider: "google", uid: "uid_123", email: "komu@example.com", name: "コムサン")
  end
  let(:signup_token) { TokenIssuer.issue_signup_token(identity) }

  describe ".call" do
    context "正常系" do
      it "ユーザーが作成される" do
        result = described_class.call(signup_token: signup_token, nickname: "コムサン", username: "komu")
        expect(result[:access_token]).to be_present
      end
    end

    context "異常系" do
      it "signup_token が不正なとき UnauthorizedError を raise する" do
        expect { described_class.call(signup_token: "invalid", nickname: "コムサン", username: "komu") }
          .to raise_error(UnauthorizedError)
      end
    end
  end
end
```

`signup_token` は自前の JWT なので、スタブせず `TokenIssuer` で本物を発行する。

## Request spec

**rswag DSL で書く**。テストと Swagger ドキュメントを兼ねるため、通常の RSpec 記法は使わない。

ステータスコードごとに `response` ブロックを書き、`run_test!` で実際にリクエストを投げてテストする。

```ruby
# spec/requests/v1/me_spec.rb
require "swagger_helper"

RSpec.describe "マイページ系", type: :request do
  path "/v1/me" do
    get "マイプロフィール取得API" do
      tags "マイページ系"
      produces "application/json"
      security [ Bearer: [] ]

      response "200", "プロフィール取得成功" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode)
            .with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
        end

        schema "$ref" => "#/components/schemas/User"
        run_test!
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }

        before do
          allow(TokenIssuer).to receive(:decode)
            .with("invalid_token", purpose: "access").and_return(nil)
        end

        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end
end
```

### 認証のテスト

**`purpose` を必ず `with` に含める。** `TokenIssuer.decode` は `purpose` を必須キーワード
引数で受け取るため、省略すると verifying partial double がシグネチャ違反で落ちる。

| 認証方式 | spec での渡し方 |
|---|---|
| アクセストークン（`v1/me/` 等） | `let(:Authorization) { "Bearer valid_token" }` + `TokenIssuer.decode` をスタブ |
| `signup_token` Cookie（`POST /v1/users` / `GET /v1/auth/signup_context`） | `let(:Cookie) { "signup_token=#{TokenIssuer.issue_signup_token(identity)}" }` |
| `refresh_token` Cookie（`POST /v1/auth/refresh`） | `let(:Cookie) { "refresh_token=#{token}" }` |
| `oauth_state` Cookie（`GET /auth/:provider/callback`） | `headers: { "Cookie" => "oauth_state=#{cookie}" }` |

**Cookie 系は本物のトークンを発行する。** 自前の JWT なので `TokenIssuer` /
`Oauth::State` をそのまま呼べる。スタブすると `purpose` の検証（実装の本体）を
テストしないことになる。

Rack 3 では `Set-Cookie` が複数あると配列になるため、まとめて1つの文字列にして検証する。

```ruby
set_cookie = Array(response.headers["Set-Cookie"]).join("\n")
expect(set_cookie).to match(/refresh_token=/i)
```

スペックが通ったら swagger.yaml を生成する。

```bash
bundle exec rails rswag:specs:swaggerize
```

## 外部APIのモック

OAuth プロバイダと楽天書籍APIは実際に叩かない。**すべて WebMock で HTTP レベルにスタブする。**

```ruby
# 楽天書籍API
stub_request(:get, /app\.rakuten\.co\.jp\/services\/api\/BooksBook/)
  .to_return(status: 200, body: { Items: [{ Item: { isbn: "9784873116068", title: "テスト本", author: "著者名" } }] }.to_json)
```

### OAuth プロバイダ

**JWKS のモックは不要。** `id_token` は token endpoint から直接受け取るため、
署名検証を行わない（[ADR 009](../decisions/009-authentication.md)）。
スタブするのはトークンエンドポイントと GitHub の User API だけである。

```ruby
# トークンエンドポイント（Google）
stub_request(:post, Oauth::Providers::Google::TOKEN_ENDPOINT)
  .to_return(status: 200, body: { id_token: id_token }.to_json,
             headers: { "Content-Type" => "application/json" })

# トークンエンドポイント（GitHub）
stub_request(:post, Oauth::Providers::Github::TOKEN_ENDPOINT)
  .to_return(status: 200, body: { access_token: "gho_xxx" }.to_json,
             headers: { "Content-Type" => "application/json" })

# GitHub の本人情報（/user と /user/emails の2本が必要）
stub_request(:get, "#{Oauth::Providers::Github::API_BASE}/user")
  .to_return(status: 200, body: { id: 12_345, name: "コムサン", login: "komusan" }.to_json,
             headers: { "Content-Type" => "application/json" })

stub_request(:get, "#{Oauth::Providers::Github::API_BASE}/user/emails")
  .to_return(status: 200,
             body: [ { email: "komu@example.com", primary: true, verified: true } ].to_json,
             headers: { "Content-Type" => "application/json" })
```

Google の `id_token` は署名検証されないため、**鍵は何でもよい。**
検証対象のクレーム（`iss` / `aud` / `exp` / `email_verified`）を入れて自分で組み立てる。

```ruby
let(:claims) do
  { iss: "https://accounts.google.com", aud: client_id, sub: "108512345678901234567",
    email: "user@example.com", email_verified: true, name: "コムサン",
    exp: 10.minutes.from_now.to_i }
end

# 実装が JWT.decode(..., false) で読む前提なので、鍵は何でもよい
def id_token(overrides = {})
  JWT.encode(claims.merge(overrides), "signed-by-google", "HS256")
end
```

異常系は `id_token(aud: "other-app")` のようにクレームを1つずつ壊して書く。

**GitHub 特有の異常系も忘れずに書く。** 失敗時も 200 で `{ error: ... }` を返すため。

```ruby
stub_request(:post, Oauth::Providers::Github::TOKEN_ENDPOINT)
  .to_return(status: 200, body: { error: "bad_verification_code" }.to_json,
             headers: { "Content-Type" => "application/json" })
```

### 環境変数

プロバイダ層は `ENV.fetch` を使うため、未設定だと `KeyError` になる。
**spec 側でも明示して実行環境に依存させない。**

```ruby
around do |example|
  original = ENV.to_h
  ENV["GOOGLE_OAUTH_CLIENT_ID"]     = "google-client-id"
  ENV["GOOGLE_OAUTH_CLIENT_SECRET"] = "google-client-secret"
  ENV["API_BASE_URL"]               = "https://api.example.com"
  ENV["FRONTEND_URL"]               = "https://app.example.com"
  example.run
ensure
  ENV.replace(original)
end
```

# テスト

## 基本ルール

- **spec を先に書く**（TDD：実装前に spec を書く）
- **`described_class` を使う**（クラス名をハードコードしない）
- **外部APIは必ずモックする**（Clerk・楽天書籍APIを実際に叩かない）

## 構成

```
spec/
├── rails_helper.rb        # RailsとRSpecの統合設定
├── spec_helper.rb         # RSpec本体の設定
├── swagger_helper.rb      # rswag設定（Request specで require する）
├── factories/             # FactoryBot（テストデータのひな形）
│   ├── users.rb
│   ├── books.rb
│   └── user_books.rb
├── models/                # Modelのバリデーションテスト
│   └── user_spec.rb
├── services/              # Serviceのビジネスロジックテスト
│   ├── users/
│   │   └── create_service_spec.rb
│   └── auth/
│       └── login_service_spec.rb
└── requests/              # APIエンドポイントテスト
    └── v1/
        └── users_spec.rb
```

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
  describe ".call" do
    context "正常系" do
      it "ユーザーが作成される" do
        allow(ClerkClient).to receive(:verify).and_return({ user_id: "clerk_123" })
        result = described_class.call(valid_params)
        expect(result).to be_persisted
      end
    end

    context "異常系" do
      it "Clerkトークンが無効なとき例外を raise する" do
        allow(ClerkClient).to receive(:verify).and_raise(ClerkClient::UnauthorizedError)
        expect { described_class.call(valid_params) }.to raise_error(ClerkClient::UnauthorizedError)
      end
    end
  end
end
```

## Request spec

**rswag DSL で書く**。テストと Swagger ドキュメントを兼ねるため、通常の RSpec 記法は使わない。

ステータスコードごとに `response` ブロックを書き、`run_test!` で実際にリクエストを投げてテストする。

```ruby
# spec/requests/v1/users_spec.rb
require "swagger_helper"

RSpec.describe "Users API" do
  path "/v1/users" do
    post "ユーザーを作成する" do
      tags "Users"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          username: { type: :string }
        },
        required: [ "username" ]
      }

      response "201", "作成成功" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { username: "komu" } }
        before { allow(ClerkClient).to receive(:verify).and_return({ user_id: "clerk_123" }) }
        schema "$ref" => "#/components/schemas/User"
        run_test!
      end

      response "422", "バリデーションエラー" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { username: "" } }
        before { allow(ClerkClient).to receive(:verify).and_return({ user_id: "clerk_123" }) }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end

      response "401", "認証エラー" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:body) { { username: "komu" } }
        before { allow(ClerkClient).to receive(:verify).and_raise(ClerkClient::UnauthorizedError) }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end
end
```

スペックが通ったら swagger.yaml を生成する。

```bash
bundle exec rails rswag:specs:swaggerize
```

## 外部APIのモック

Clerkと楽天書籍APIは実際に叩かない。

```ruby
# Clerk
allow(ClerkClient).to receive(:verify).and_return({ user_id: "clerk_123" })
allow(ClerkClient).to receive(:verify).and_raise(ClerkClient::UnauthorizedError)

# 楽天書籍API（HTTPレベルでモック）
stub_request(:get, /app\.rakuten\.co\.jp\/services\/api\/BooksBook/)
  .to_return(status: 200, body: { Items: [{ Item: { isbn: "9784873116068", title: "テスト本", author: "著者名" } }] }.to_json)
```

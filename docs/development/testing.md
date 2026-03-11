# テスト

## 基本ルール

- **spec を先に書く**（TDD：実装前に spec を書く）
- **`described_class` を使う**（クラス名をハードコードしない）
- **外部APIは必ずモックする**（Clerk・Google Books を実際に叩かない）

## 構成

```
spec/
├── rails_helper.rb        # RailsとRSpecの統合設定
├── spec_helper.rb         # RSpec本体の設定
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

ステータスコードとレスポンス形式を確認する。

```ruby
# spec/requests/v1/users_spec.rb
RSpec.describe "POST /v1/users", type: :request do
  context "正常系" do
    it "201を返す" do
      allow(ClerkClient).to receive(:verify).and_return({ user_id: "clerk_123" })
      post "/v1/users", params: valid_params
      expect(response).to have_http_status(:created)
    end
  end

  context "バリデーションエラー" do
    it "422とエラー形式を返す" do
      post "/v1/users", params: { username: "" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body).dig("error", "code")).to eq("UNPROCESSABLE_ENTITY")
    end
  end

  context "認証エラー" do
    it "401を返す" do
      allow(ClerkClient).to receive(:verify).and_raise(ClerkClient::UnauthorizedError)
      post "/v1/users", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

## 外部APIのモック

ClerkとGoogle BooksのAPIは実際に叩かない。

```ruby
# Clerk
allow(ClerkClient).to receive(:verify).and_return({ user_id: "clerk_123" })
allow(ClerkClient).to receive(:verify).and_raise(ClerkClient::UnauthorizedError)

# Google Books（HTTPレベルでモック）
stub_request(:get, "https://www.googleapis.com/books/v1/volumes/...")
  .to_return(status: 200, body: { id: "abc123", volumeInfo: { title: "テスト本" } }.to_json)
```

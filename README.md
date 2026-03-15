# Shelfie Backend

本棚・読書記録共有サービス **Shelfie** の JSON API サーバー。

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| 言語 | Ruby 3.4.2 |
| フレームワーク | Rails 8.1.2 (API mode) |
| データベース | PostgreSQL 16 |
| 認証 | Clerk (JWT) |
| テスト | RSpec + FactoryBot |
| 型チェック | Steep (RBS) |
| Lint | RuboCop |
| CI | GitHub Actions |
| デプロイ | Kamal |
| ローカル S3 | LocalStack |

## 必要条件

- Docker / Docker Compose
- （オプション）Ruby 3.4.2（コンテナ外で実行する場合）

## ローカル開発環境セットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd shelfie-backend
```

### 2. 環境変数の設定

```bash
cp .env.example .env.local
```

`.env.local` を編集して必要な値を設定する。

| 変数名 | 説明 |
|--------|------|
| `DB_HOST` | DB ホスト（Docker なら `db`） |
| `DB_PASSWORD` | PostgreSQL パスワード |
| `CLERK_SECRET_KEY` | Clerk ダッシュボードから取得 |
| `JWT_SECRET_KEY` | JWT 署名用シークレット |
| `DEV_JWT_SECRET` | 開発用 JWT シークレット（デフォルト: `dev-secret-change-me`） |
| `DEV_CLERK_USER_ID` | 開発用 Clerk ユーザー ID |
| `DEV_EMAIL` | 開発用メールアドレス |
| `AWS_ACCESS_KEY_ID` | LocalStack 用（デフォルト: `test`） |
| `AWS_SECRET_ACCESS_KEY` | LocalStack 用（デフォルト: `test`） |
| `S3_BUCKET_NAME` | S3 バケット名（デフォルト: `shelfie-local`） |

### 3. コンテナの起動

```bash
docker compose up
```

### 4. データベースのセットアップ

```bash
docker compose exec web bundle exec rails db:create db:migrate
```

アプリは `http://localhost:3000` で起動する。

## よく使うコマンド

```bash
# テスト実行
bundle exec rspec

# Lint
bundle exec rubocop

# 型チェック
bundle exec steep check

# セキュリティスキャン
bin/brakeman --no-pager

# Swagger ドキュメント生成
bundle exec rails rswag:specs:swaggerize
```

コンテナ内で実行する場合は先頭に `docker compose exec web` を付ける。

## 開発用 JWT 発行

Clerk なしでローカル開発・テストを行うための JWT を発行できる。

```bash
# .env.local の設定値を使用
./scripts/gen_dev_jwt.sh

# 引数で上書き
./scripts/gen_dev_jwt.sh <CLERK_USER_ID> <EMAIL>
```

> web コンテナが起動している状態で実行すること。

## API エンドポイント

| メソッド | パス | 説明 |
|----------|------|------|
| `GET` | `/up` | ヘルスチェック |
| `GET` | `/api-docs` | Swagger UI |
| `POST` | `/v1/users` | ユーザー作成 |

Swagger UI: `http://localhost:3000/api-docs`

## ディレクトリ構成

```
app/
  controllers/        # リクエストハンドラ
  models/
    queries/          # 複雑なマルチテーブルクエリ
  services/           # ビジネスロジック
  serializers/        # JSON レスポンス整形
  constants/          # エラーコード・メッセージ定数
lib/
  clients/            # 外部 API クライアント (Clerk, Google Books)
config/
  locales/            # バリデーションメッセージ (ja)
db/
  migrations/
spec/
  models/
  services/
  requests/           # API エンドポイントテスト (rswag)
  factories/
docs/development/     # 開発ドキュメント
scripts/              # 開発用スクリプト
```

詳細は `docs/development/` を参照。

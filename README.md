# Shelfie Backend

本棚・読書記録共有サービス **Shelfie** の JSON API サーバー。

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| 言語 | Ruby 3.4.2 |
| フレームワーク | Rails 8.1.2 (API mode) |
| データベース | PostgreSQL 16 |
| 認証 | OAuth 2.0 (Google / GitHub) + 自前 JWT |
| テスト | RSpec + FactoryBot |
| 型チェック | Steep (RBS) |
| Lint | RuboCop |
| CI | GitHub Actions |
| デプロイ | GitHub Actions + SSM Run Command（ADR 011） |

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
| `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` | Google Cloud Console から取得 |
| `GITHUB_OAUTH_CLIENT_ID` / `GITHUB_OAUTH_CLIENT_SECRET` | GitHub OAuth App から取得 |
| `API_BASE_URL` | このアプリ自身の公開 URL（`redirect_uri` の組立に使う。ローカルは `http://localhost:8080`） |
| `FRONTEND_URL` | OAuth 完了後のリダイレクト先（ローカルは `http://localhost:3000`） |

### 3. コンテナの起動

```bash
docker compose up
```

### 4. データベースのセットアップ

```bash
docker compose exec web bundle exec rails db:create db:migrate
```

アプリは `http://localhost:8080` で起動する（`docker-compose.yml` のポートマッピング）。

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

## 開発時のログイン

**開発環境でも本番と同じ OAuth フローを通す。** トークンを手で渡す開発用バイパスは無い。

1. IdP にローカル用のリダイレクト URI を登録する
   - Google: `http://localhost:8080/auth/google/callback`（Google は localhost に限り http を許可）
   - GitHub: `http://localhost:8080/auth/github/callback`
2. `.env.local` に OAuth の4件と `API_BASE_URL` / `FRONTEND_URL` を設定する
3. **ブラウザで** `http://localhost:8080/auth/google` を開く

`curl` では通らない（Cookie の往復とトップレベル遷移が必要）。
手順の詳細とエラーコードの見分け方 → `docs/development/docker.md`

## API エンドポイント

| メソッド | パス | 説明 |
|----------|------|------|
| `GET` | `/up` | ヘルスチェック |
| `GET` | `/api-docs` | Swagger UI |
| `GET` | `/auth/:provider` | OAuth の開始（`google` / `github`） |
| `GET` | `/auth/:provider/callback` | OAuth のコールバック |
| `POST` | `/v1/users` | ユーザー作成 |

一覧は `docs/api/endpoints.md` を参照。

Swagger UI: `http://localhost:8080/api-docs`

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
  clients/            # 外部 API クライアント (楽天書籍API)
  oauth/              # OAuth プロバイダ層 (Google / GitHub)
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
```

詳細は `docs/development/` を参照。

# Docker 環境構築

## 概要

ローカル開発環境を Docker で統一することで、OS 環境に依存しない一貫した開発環境を実現します。

---

## サービス構成

| サービス | イメージ | 役割 |
|---|---|---|
| `web` | Ruby（Dockerfile） | Rails API サーバー |
| `db` | postgres | データベース（PostgreSQL） |

> OAuth の IdP（Google / GitHub）は外部サービスのため Docker では管理しない。
> 環境変数でクライアント ID / シークレットを渡すのみ。

---

## ファイル構成

```
shelfie-backend/
├── Dockerfile
├── docker-compose.yml
├── .env.local        # 機密情報（Git 管理外）
└── .env.example      # 環境変数の一覧（Git 管理）
```

---

## Dockerfile

Rails コンテナのビルド手順を定義します。

```dockerfile
FROM ruby:3.x.x
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
CMD ["rails", "server", "-b", "0.0.0.0"]
```

| 命令 | 説明 |
|---|---|
| `FROM` | Ruby のベースイメージを指定 |
| `WORKDIR /app` | 作業ディレクトリを設定（以降のコマンドはここで実行） |
| `COPY` | Gemfile・Gemfile.lock をコンテナにコピー |
| `RUN bundle install` | gem をインストール |
| `CMD` | コンテナ起動時に Rails サーバーを起動 |

---

## docker-compose.yml

2 つのサービスをまとめて管理します。

```yaml
services:
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app          # ホストのコードをリアルタイムで反映
    env_file:
      - .env
    depends_on:
      - db

  db:
    image: postgres:16
    env_file:
      - .env
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

---

## 環境変数

機密情報は `.env.local` で管理し、`.env.example` をリポジトリに含めます。

全項目は `.env.example` を参照。OAuth に必要なのは以下6件である。

| 変数名 | 説明 |
|---|---|
| `GOOGLE_OAUTH_CLIENT_ID` | Google Cloud Console の OAuth 2.0 クライアント ID |
| `GOOGLE_OAUTH_CLIENT_SECRET` | 同クライアントシークレット |
| `GITHUB_OAUTH_CLIENT_ID` | GitHub OAuth App のクライアント ID |
| `GITHUB_OAUTH_CLIENT_SECRET` | 同クライアントシークレット |
| `API_BASE_URL` | **このアプリ自身の公開 URL**（末尾スラッシュなし）。`redirect_uri` の組立に使う。ローカルは `http://localhost:8080` |
| `FRONTEND_URL` | OAuth 完了後のリダイレクト先。ローカルは `http://localhost:3000` |

`API_BASE_URL` と `FRONTEND_URL` は**固定値として使う。**
`params` 由来の値を混ぜるとオープンリダイレクトになる。

> `.env.local` は `.gitignore` に追加し、Git 管理外とする。
> 新しく開発に参加する場合は `.env.example` をコピーして `.env.local` を作成し、値を設定する。

---

## ボリュームマウント

`docker-compose.yml` の `volumes: - .:/app` により、ホストのコードをコンテナにリアルタイムで反映します。

- ローカルでコードを編集 → コンテナ内にも即時反映
- Rails は development モードでコードの変更を自動で検知・再読み込み
- コンテナの再ビルドは不要

---

## セットアップ手順

```bash
# .env.local を作成
cp .env.example .env.local
# 値を設定（DB_PASSWORD, JWT_SECRET_KEY, OAuth の4件など）

# コンテナを起動
docker compose up

# DB の作成・マイグレーション（初回のみ）
docker compose exec web rails db:create db:migrate
```

---

## 開発時のログイン

**開発環境でも本番と同じ OAuth フローを通す。**
トークンを手で渡す開発用バイパスは廃止した（入口がリダイレクトになったため置き場所がない）。

### 1. IdP に localhost のリダイレクト URI を登録する

`redirect_uri` は `{API_BASE_URL}/auth/{provider}/callback` で組み立てられる。
IdP 側に登録した値と**完全一致**していないとコード交換が失敗する。

| IdP | 登録する リダイレクト URI |
|---|---|
| Google Cloud Console | `http://localhost:8080/auth/google/callback` |
| GitHub OAuth App | `http://localhost:8080/auth/github/callback` |

> Google は **localhost に限り `http`** を許可する。本番は `https` 必須。

### 2. `.env.local` に4件のクライアント情報と2件の URL を設定する

```
GOOGLE_OAUTH_CLIENT_ID=...
GOOGLE_OAUTH_CLIENT_SECRET=...
GITHUB_OAUTH_CLIENT_ID=...
GITHUB_OAUTH_CLIENT_SECRET=...
API_BASE_URL=http://localhost:8080
FRONTEND_URL=http://localhost:3000
```

### 3. ブラウザで入口を開く

```
http://localhost:8080/auth/google
```

**`curl` ではなくブラウザで開く。** Cookie（`oauth_state`）の往復と
トップレベル遷移が必要なため。

`COOKIE_DOMAIN` は未設定のままでよい。Cookie は `localhost:3000` ⇄ `localhost:8080` で
**ポートが違ってもホストが同じなら共有される。**

### 失敗したときの見分け方

コールバックは失敗も 302 で返すため、遷移先のクエリを見る。

| リダイレクト先 | 意味 |
|---|---|
| `{FRONTEND_URL}/?...` | ログイン成功（`refresh_token` Cookie が付く）|
| `{FRONTEND_URL}/signup` | 新規ユーザー（`signup_token` Cookie が付く）|
| `/login?error=invalid_state` | `oauth_state` Cookie が無い / 期限切れ（10分）/ state 不一致 |
| `/login?error=provider_error` | コード交換の失敗。**`redirect_uri` の登録ミスが最も多い** |
| `/login?error=email_unavailable` | GitHub で primary かつ verified なメールが無い |
| `/login?error=email_already_registered` | 同じメールが別プロバイダで登録済み（P1）|

全経路の一覧 → [認証フロー](../architecture/auth.md#コールバックのエラー分岐全経路)

# Docker 環境構築

## 概要

ローカル開発環境を Docker で統一することで、OS 環境に依存しない一貫した開発環境を実現します。

---

## サービス構成

| サービス | イメージ | 役割 |
|---|---|---|
| `web` | Ruby（Dockerfile） | Rails API サーバー |
| `db` | postgres | データベース（PostgreSQL） |

> Clerk はクラウドサービスのため Docker では管理しない。環境変数で API キーを渡すのみ。

---

## ファイル構成

```
shelfie-backend/
├── Dockerfile
├── docker-compose.yml
├── .env              # 機密情報（Git 管理外）
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

機密情報は `.env` で管理し、`.env.example` をリポジトリに含めます。

### .env.example

```
# Database
DB_HOST=db
DB_PORT=5432
DB_NAME=shelfie_development
DB_USER=postgres
DB_PASSWORD=

# Clerk
CLERK_SECRET_KEY=

# JWT
JWT_SECRET_KEY=
```

> `.env` は `.gitignore` に追加し、Git 管理外とする。
> 新しく開発に参加する場合は `.env.example` をコピーして `.env` を作成し、値を設定する。

---

## ボリュームマウント

`docker-compose.yml` の `volumes: - .:/app` により、ホストのコードをコンテナにリアルタイムで反映します。

- ローカルでコードを編集 → コンテナ内にも即時反映
- Rails は development モードでコードの変更を自動で検知・再読み込み
- コンテナの再ビルドは不要

---

## セットアップ手順

```bash
# .env を作成
cp .env.example .env
# 値を設定（DB_PASSWORD, CLERK_SECRET_KEY, JWT_SECRET_KEY など）

# コンテナを起動
docker compose up

# DB の作成・マイグレーション（初回のみ）
docker compose exec web rails db:create db:migrate
```

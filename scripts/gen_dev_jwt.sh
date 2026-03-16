#!/bin/bash
# テスト用JWTを発行する（コンテナ内で rake dev:clerk_jwt を実行）
set -euo pipefail

ENV_FILE=".env.local"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE が見つかりません" >&2
  exit 1
fi

# .env.local から DEV_CLERK_USER_ID / DEV_EMAIL を読み込む
CLERK_USER_ID=$(grep '^DEV_CLERK_USER_ID=' "$ENV_FILE" | cut -d'=' -f2-)
EMAIL=$(grep '^DEV_EMAIL=' "$ENV_FILE" | cut -d'=' -f2-)

# コマンドライン引数で上書き可能（任意）
CLERK_USER_ID=${1:-$CLERK_USER_ID}
EMAIL=${2:-$EMAIL}

if [ -z "$CLERK_USER_ID" ]; then
  echo "Error: CLERK_USER_ID が未設定（.env.local の DEV_CLERK_USER_ID または引数で指定）" >&2
  exit 1
fi

if [ -z "$EMAIL" ]; then
  echo "Error: EMAIL が未設定（.env.local の DEV_EMAIL または引数で指定）" >&2
  exit 1
fi

if ! docker compose ps web | grep -q "Up"; then
  echo "Error: web コンテナが起動していません。先に 'docker compose up -d' を実行してください。" >&2
  exit 1
fi

docker compose exec web bundle exec rake dev:clerk_jwt \
  CLERK_USER_ID="$CLERK_USER_ID" \
  EMAIL="$EMAIL"

# 本番の秘密の管理

本番の環境変数は **AWS Systems Manager Parameter Store** に置く。
決定の理由は [ADR 011](../decisions/011-deployment.md) を参照。

**このドキュメントに値そのものを書かない。** 書くのは置き場所と手順だけ。

## パス設計

```
/shelfie/production/app/*     → Rails に渡す（EC2 が app.env に落とす）
/shelfie/production/host/*    → ホスト側で使う。Rails には渡さない
```

**分けているのは、Cloudflare Tunnel のトークンを Rails のプロセス環境に載せないため。**
同じ階層に置くと `get-parameters-by-path` の一括取得で `app.env` に混入する。

## 何をどちらの型で置くか

| 型 | 作り方 | 変数 |
|---|---|---|
| **String** | **CloudFormation が作る**（`cfn-shelfie-app.yaml`） | `API_BASE_URL` / `FRONTEND_URL` / `COOKIE_DOMAIN` / `CORS_ALLOWED_ORIGINS` / `RAKUTEN_ORIGIN` / `GOOGLE_OAUTH_CLIENT_ID` / `GITHUB_OAUTH_CLIENT_ID` |
| **SecureString** | **人間が手で投入する** | `SECRET_KEY_BASE` / `DATABASE_URL` / `GOOGLE_OAUTH_CLIENT_SECRET` / `GITHUB_OAUTH_CLIENT_SECRET` / `RAKUTEN_APP_ID` / `RAKUTEN_ACCESS_KEY` / `CLOUDFLARE_TUNNEL_TOKEN` |

**`SecureString` は CloudFormation で作成できない**（`AWS::SSM::Parameter` の `Type` は
`String` / `StringList` のみ）。この制約を分離線として使っている。
テンプレートは git に入るので、**秘密が書けない方が安全**である。

`client_id` を String 側に置いているのは、**認可 URL のクエリに平文で載る値**だから。
隠す意味がない。秘密なのは `client_secret` だけ。

### 不要な変数

| 変数 | 理由 |
|---|---|
| `RAILS_MASTER_KEY` | credentials を使わない（[ADR 011](../decisions/011-deployment.md)） |
| JWT 署名鍵の専用変数 | 署名鍵は `secret_key_base` を使う（`lib/token_issuer.rb`） |
| `RAILS_ENV` | `Dockerfile` が設定している |

## 秘密の出所

| 変数 | 取得元 |
|---|---|
| `SECRET_KEY_BASE` | `bin/rails secret` で生成する |
| `DATABASE_URL` | Neon のダッシュボード（**pooled** の接続文字列） |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Google Cloud Console |
| `GITHUB_OAUTH_CLIENT_SECRET` | GitHub の Developer settings |
| `RAKUTEN_APP_ID` / `RAKUTEN_ACCESS_KEY` | 楽天ウェブサービスのアプリ管理 |
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Zero Trust の Tunnel 作成画面 |

> `SECRET_KEY_BASE` は **Shelfie の認証システム全体の唯一の署名鍵**である
> （access / refresh / signup / oauth_state の4種すべて。`lib/token_issuer.rb` / `lib/oauth/state.rb`）。
> **漏れると任意の `user_id` のアクセストークンを偽造できる。**

## 投入する

### シェル履歴に残さない

**`aws ssm put-parameter --value 'xxx'` は履歴（`~/.zsh_history`）に平文で残る。**
Parameter Store を暗号化しても、手元に平文が残っては意味がない。

その場のシェルに次の関数を定義する（**ファイルに保存しない**）。

```bash
export AWS_PROFILE=shelfie-prod
export AWS_REGION=ap-northeast-1
aws sts get-caller-identity          # ★ 向き先を必ず確認してから

put_secret() {
  local name="$1" value
  printf 'value for %s: ' "$name" >&2
  read -rs value                     # 入力がエコーされず、履歴にも残らない
  echo >&2
  aws ssm put-parameter --name "$name" --type SecureString --value "$value" --overwrite
  unset value
}
```

> `--key-id` を省略すると AWS 管理キー `alias/aws/ssm` が使われる。**追加費用はかからない。**

### 7個を投入する

```bash
put_secret /shelfie/production/app/SECRET_KEY_BASE
put_secret /shelfie/production/app/DATABASE_URL
put_secret /shelfie/production/app/GOOGLE_OAUTH_CLIENT_SECRET
put_secret /shelfie/production/app/GITHUB_OAUTH_CLIENT_SECRET
put_secret /shelfie/production/app/RAKUTEN_APP_ID
put_secret /shelfie/production/app/RAKUTEN_ACCESS_KEY
put_secret /shelfie/production/host/CLOUDFLARE_TUNNEL_TOKEN
```

**`CLOUDFLARE_TUNNEL_TOKEN` は `cfn-shelfie-app.yaml` を適用する前に投入する。**
EC2 の user-data がこれを読むため、無いと初期化に失敗する。

## 検証する

**値を表示せずに**、存在と型だけを確認する。

```bash
aws ssm get-parameters-by-path --path /shelfie/production/ --recursive \
  --query 'Parameters[].[Name,Type]' --output table
```

- `SecureString` が **7個**（`app/` に6個・`host/` に1個）
- `String` が **7個**（すべて `app/`。CloudFormation 由来）

名前の綴りを必ず確認する。デプロイスクリプトが `grep "^KEY="` で存在を検証するため、
**1文字違うと起動に失敗する。**

`DATABASE_URL` だけは形式を見る価値がある。パスワードはマスクして表示する。

```bash
aws ssm get-parameter --name /shelfie/production/app/DATABASE_URL --with-decryption \
  --query 'Parameter.Value' --output text | sed -E 's/:[^:@]+@/:****@/'
```

- **`-pooler` が含まれる**（含まれないものは direct connection）
- **`sslmode=require` が含まれる**

`COOKIE_DOMAIN` も確認する。

```bash
aws ssm get-parameter --name /shelfie/production/app/COOKIE_DOMAIN \
  --query 'Parameter.Value' --output text
```

- **`.shelfie.jp`**（先頭のドットが要る。`.com` ではない）

> 空またはホスト名だけだと**ホストオンリー Cookie** になり、
> **API 通信は動くまま Next.js 側の判定だけが静かに死ぬ**（[ADR 010](../decisions/010-hosting.md) の既知の罠）。
> 「ログインできたのにログイン状態にならない」という症状になる。

投入時に履歴が汚れていないことも確認する。

```bash
history | grep -c put-parameter      # 関数経由なら値は含まれない
```

## 値を更新する

```bash
put_secret /shelfie/production/app/DATABASE_URL
```

**反映には再デプロイが必要。** `app.env` はデプロイのたびに生成し直される。
値を変えただけでは動いているコンテナには届かない。

## 誰が読めるか

| 主体 | 読める範囲 |
|---|---|
| **EC2 インスタンスロール**（`shelfie-ec2`） | `/shelfie/production/*` の**すべて** |
| **deploy ワークフロー**（`shelfie-gha-deploy`） | **なし。** コマンドを送る権限だけ |
| **migrate ワークフロー**（`shelfie-gha-migrate`） | `DATABASE_URL` と `SECRET_KEY_BASE` の**2つだけ** |

**デプロイのとき、秘密は GitHub Actions を1つも通らない。**
EC2 がインスタンスロールで Parameter Store から直接取得する。

migrate だけは Neon に直接繋ぐため2つ読むが、**ARN を個別に列挙**していて
ワイルドカードを使っていない（`rails db:prepare` の起動に必要な秘密が
この2つだけであることは実測で確認済み）。

## 関連ドキュメント

- [ADR 011: 本番デプロイ方式](../decisions/011-deployment.md) — Parameter Store を選んだ理由
- [ADR 012: AWS アカウント構成](../decisions/012-aws-account.md)
- [infra/README.md](../../infra/README.md) — テンプレートの適用手順

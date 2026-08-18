# デプロイ

本番へのデプロイは GitHub Actions の3本のワークフローで行う。**決定の理由は
[ADR 011](../decisions/011-deployment.md)**、秘密の置き場は [本番の秘密の管理](./secrets.md) を参照。

ランナーは EC2 に SSH しない。**SSM Run Command 経由**でシェルスクリプトを実行させるため、
SSH 鍵が要らず、**秘密がランナーを1つも通らない**（EC2 がインスタンスロールで直接取得する）。

## ワークフロー

| ファイル | トリガー | Environment | 内容 |
|---|---|---|---|
| `.github/workflows/build.yml` | `push: main`（自動） | なし | arm64 ビルド → GHCR に push |
| `.github/workflows/migrate.yml` | `workflow_dispatch` | `production-migrate`（**承認必須**） | 指定タグのイメージで `db:prepare` |
| `.github/workflows/deploy.yml` | `workflow_dispatch` | `production-deploy` | 指定タグを EC2 に配置 → 検証 |

`ci.yml`（PR の品質ゲート）とは役割が違う。`build.yml` は成果物の生成のみを担い、
**`ci.yml` の成否を待たない**。デプロイが手動なので、CI が赤いコミットは人間が選ばない限り本番に出ない。

**`push: main` での自動デプロイはしない。** マイグレーションが手動のため、
自動デプロイにすると「マージ → 自動デプロイ → 未マイグレーションの DB に新コードが当たる」が起きる。

### イメージのタグ

`sha-<短縮SHA 7桁>` のみ。**`latest` は付けない**（今どれが動いているかが曖昧になるため）。
`migrate.yml` / `deploy.yml` の `image_tag` を省略すると `main` の HEAD から同じ規則で組み立てる。

## GitHub 側の設定（手作業）

ワークフローを置くだけでは動かない。以下はリポジトリの Settings で人間が設定する。

### 1. Environments

| 名前 | 保護 |
|---|---|
| `production-deploy` | 承認なし |
| `production-migrate` | **Required reviewers を設定する** |

**承認は「戻せるかどうか」で置く。** スキーマ変更だけが不可逆なので、そこにだけゲートを掛ける。

Environment 名は IAM ロールの信頼ポリシーの `sub` 条件
（`repo:<owner>/<repo>:environment:production-migrate`）に埋め込まれている。
**ワークフローの YAML を書き換えても承認は迂回できない**（OIDC トークンが発行されず AssumeRole が通らない）。

### 2. Variables（Repository variables）

| 変数名 | 値の出所 |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | `cfn-shelfie-cicd` スタックの `DeployRoleArn` 出力 |
| `AWS_MIGRATE_ROLE_ARN` | 同スタックの `MigrateRoleArn` 出力 |
| `AWS_REGION` | `ap-northeast-1` |
| `EC2_INSTANCE_ID` | `cfn-shelfie-app` スタックが作るインスタンスの ID |

### 3. Secrets は1つも登録しない

**登録する必要がない。** AWS の認証は OIDC、GHCR は `GITHUB_TOKEN`、
アプリの秘密は Parameter Store から EC2 が直接読む。

### 4. GHCR のパッケージを public にする

**`build.yml` の初回実行後に1回だけ行う。** GHCR のコンテナパッケージは初回 push 時に
private で作られるため、そのままだと EC2 の `docker pull` が unauthorized で落ちる。

```
リポジトリの Packages → shelfie-backend → Package settings → Change visibility → Public
```

EC2 側で `docker login` をしないのは、private にすると **PAT を Parameter Store に置き、
期限切れのたびに更新する**運用が発生するため（[ADR 011](../decisions/011-deployment.md)）。
リポジトリが public なのでイメージを private にしても隠れるものは無い。

## 手順

```
1. main にマージする              → build.yml が自動で走り、GHCR に sha-xxxxxxx が積まれる
2. スキーマ変更があるとき          → migrate.yml を実行（承認が要る）
3. deploy.yml を実行              → EC2 のコンテナを差し替え、公開 URL で疎通確認
```

**マイグレーションを先に、デプロイを後に。** 逆順にすると新コードが古いスキーマに当たる。

### deploy.yml が EC2 でやること

1. `/opt/shelfie/.initialized` の確認（user-data の失敗は CloudFormation が検知しないため）
2. Parameter Store から `/shelfie/production/app/` 配下を取得して `/opt/shelfie/app.env` を生成
3. **必須キーの検証** — 投入漏れを「起動してから 500」ではなく「デプロイが赤くなる」に変える
4. 未適用マイグレーションの検知（**適用はしない**。適用は `migrate.yml` の担当）
5. コンテナの差し替え（`-p 127.0.0.1:8080:8080`。SG を誤って開けたときの二重の防御）

最後にランナー側から **公開 URL の `/up`** を叩いて検証する。
EC2 の中から `localhost:8080` を叩くと、Tunnel が死んでいても成功してしまうため
Cloudflare エッジ → Tunnel → cloudflared → Rails の**経路全体**を確認する。

### 未適用マイグレーションを承知で進めるとき

expand / contract 手順のように「新コードを先に出す」場合は、
`deploy.yml` の `skip_migration_check` を `true` にする。

## 落ちたときに見るところ

| 症状 | 見るところ |
|---|---|
| `missing parameter: XXX` | Parameter Store への投入漏れ。[secrets.md](./secrets.md) の投入手順 |
| `未適用のマイグレーションが N 件あります` | `migrate.yml` を先に実行する |
| `インスタンスの初期化が未完了です` | EC2 の user-data が失敗している。`/var/log/cloud-init-output.log` |
| `manifest unknown` / `unauthorized` | そのタグが GHCR に無い（`build.yml` の完了前）か、パッケージが private のまま |
| `exec format error` | イメージ（arm64）とランナーのアーキテクチャが合っていない。**イメージを `docker run` するジョブは `ubuntu-24.04-arm` で動かす** |
| `db:migrate:status の実行に失敗しました` | DB に届かないかイメージが壊れている。**未適用0件と区別して落としている** |
| SSM が `Failed` で終わる | ジョブのログに EC2 側の stdout / stderr がそのまま出る |
| `起動確認に失敗しました` | コンテナは入れ替わったが `/up` が返らない。Tunnel かアプリの起動を疑う |

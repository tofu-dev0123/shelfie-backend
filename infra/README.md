# インフラ

Shelfie の本番環境を CloudFormation で記述する。

**設計判断の理由は書かない** — それは [ADR](../docs/decisions/README.md) の担当。
ここに書くのは**何がどこにあるか**と**どう適用するか**。

## 命名規則

### ファイル名

```
cfn-shelfie-<リソース名 または 用途名>.yaml
```

- `cfn-` … CloudFormation のテンプレートであることを示す
- `shelfie-` … プロジェクト名。**AWS アカウントを分けた後も残す**
  （ARN やスタック名を単体で見たときに、どのプロジェクトのものか分かるようにするため）
- 末尾 … **主となるリソース名**（`budget`）**または用途名**（`workload`）

例。

| ファイル | 末尾の由来 |
|---|---|
| `cfn-shelfie-budget.yaml` | リソース名（AWS Budgets） |
| `cfn-shelfie-workload.yaml` | 用途名（VPC / SG / IAM / EC2 をまとめたもの） |

**1ファイル1用途にする。** 「baseline」「common」のような曖昧な括りは避ける。
入れる場所に迷うリソースが出たら、それは新しいファイルを作る合図。

### スタック名

```
shelfie-<環境>-<リソース名 または 用途名>
```

**テンプレートには環境を書かず、環境はスタック名で表す。**
テンプレートを環境非依存に保てるので、`shelfie-stg` アカウントを作った場合に
**同じテンプレートを別のスタック名で適用できる。**

| ファイル | スタック名 |
|---|---|
| `cfn-shelfie-budget.yaml` | `shelfie-prod-budget` |
| `cfn-shelfie-workload.yaml` | `shelfie-prod-workload` |

CloudFormation のスタックに `cfn-` を付けるのは冗長なので落とす。

## テンプレート

**寿命が違うものは同じスタックに置かない。**

| テンプレート | 寿命 | 内容 |
|---|---|---|
| [`cloudformation/cfn-shelfie-budget.yaml`](./cloudformation/cfn-shelfie-budget.yaml) | **アカウントと同じ** | 予算アラート |
| [`cloudformation/cfn-shelfie-workload.yaml`](./cloudformation/cfn-shelfie-workload.yaml) | **ワークロードと同じ** | VPC / SG / IAM / OIDC / EC2 / SSM パラメータ |

ワークロードのスタックは作り直す前提で設計している。EC2 に永続データが無い
（DB は Neon、オブジェクトストレージ未使用）ため、**スタックごと削除して再作成できる。**
そのたびに消えては困るものを分けている。

## 前提

### プロファイル

Shelfie 専用の AWS アカウントを SSO で操作する。`~/.aws/config` に以下を追加する。

```ini
[profile shelfie-prod]
sso_session = my-sso
sso_account_id = <Shelfie アカウントの ID>
sso_role_name = AdministratorAccess
region = ap-northeast-1
output = json
```

`sso_session` は既存の定義を再利用する（start URL と region はそちらが持つ）。

```bash
aws sso login --profile shelfie-prod
```

### 適用前に必ず確認する

```bash
export AWS_PROFILE=shelfie-prod
export AWS_REGION=ap-northeast-1

aws sts get-caller-identity
```

**`Account` が Shelfie 専用アカウントであることを確認してから作業に入る。**

`AWS_PROFILE` を設定していないと、既定のプロファイルが向いている
**共用アカウント（`012419503930`）にスタックを作ってしまう。**
あちらは他プロジェクトが同居しているため、事故の影響が Shelfie に閉じない。

## 適用

### cfn-shelfie-budget.yaml

```bash
aws cloudformation deploy \
  --template-file infra/cloudformation/cfn-shelfie-budget.yaml \
  --stack-name shelfie-prod-budget \
  --parameter-overrides NotificationEmail='<通知先メールアドレス>'
```

月額予算を既定の $20 から変えたい場合。

```bash
  --parameter-overrides NotificationEmail='...' MonthlyBudgetUsd=30
```

**確認する。**

```bash
aws cloudformation describe-stacks --stack-name shelfie-prod-budget \
  --query 'Stacks[0].StackStatus' --output text

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

aws budgets describe-budgets --account-id "$ACCOUNT_ID" \
  --query 'Budgets[].[BudgetName,BudgetLimit.Amount,BudgetLimit.Unit]' --output table

aws budgets describe-notifications-for-budget \
  --account-id "$ACCOUNT_ID" --budget-name shelfie-monthly-cost \
  --query 'Notifications[].[NotificationType,Threshold]' --output table
```

- スタックが `CREATE_COMPLETE`（または `UPDATE_COMPLETE`）
- `shelfie-monthly-cost` / `20` / `USD`
- 通知が `ACTUAL 80` / `ACTUAL 100` / `FORECASTED 100` の3件

> **`FORECASTED` は稼働直後には発火しない。** AWS が予測を出すには数週間の課金履歴が要る。
> 最初のうちに鳴るのは `ACTUAL` の2件だけ。

### cfn-shelfie-workload.yaml

**前提**: `/shelfie/production/host/CLOUDFLARE_TUNNEL_TOKEN` が投入済みであること。
**user-data がこれを読むため、無いと初期化に失敗する。**
秘密の投入手順は [docs/development/secrets.md](../docs/development/secrets.md) を参照。

AMI は**パラメータで明示的に渡す。** SSM パブリックパラメータで自動解決する書き方は、
**スタックを更新するたびにインスタンスが置換される**（＝全断 + 再デプロイ）ため採用していない。
OS の更新をいつ行うかは人間が決める。

```bash
AMI_ID="$(aws ssm get-parameter \
  --name /aws/service/canonical/ubuntu/server/24.04/stable/current/arm64/hvm/ebs-gp3/ami-id \
  --query 'Parameter.Value' --output text)"

aws cloudformation deploy \
  --template-file infra/cloudformation/cfn-shelfie-workload.yaml \
  --stack-name shelfie-prod-workload \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      AmiId="$AMI_ID" \
      GoogleOauthClientId='<Google の client id>' \
      GithubOauthClientId='<GitHub の client id>'
```

> **`CAPABILITY_NAMED_IAM` が必要。** IAM ロールに名前を明示しているため
> （信頼ポリシーやドキュメントから参照するので、生成名だと扱いづらい）。

**適用前に変更内容を確認したい場合**は、変更セットを作って中身を見てから消せる。
リソースは作られない。

```bash
aws cloudformation create-change-set \
  --stack-name shelfie-prod-workload --change-set-name review \
  --change-set-type CREATE \
  --template-body file://infra/cloudformation/cfn-shelfie-workload.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=AmiId,ParameterValue="$AMI_ID" \
               ParameterKey=GoogleOauthClientId,ParameterValue=x \
               ParameterKey=GithubOauthClientId,ParameterValue=x

aws cloudformation describe-change-set --stack-name shelfie-prod-workload \
  --change-set-name review --query 'Changes[].ResourceChange.[ResourceType,LogicalResourceId]' --output table

aws cloudformation delete-change-set --stack-name shelfie-prod-workload --change-set-name review
aws cloudformation delete-stack --stack-name shelfie-prod-workload   # REVIEW_IN_PROGRESS の空スタックを消す
```

**確認する。**

```bash
# ★ この構成の要。ingress が0件であること
aws ec2 describe-security-groups --filters Name=tag:Project,Values=shelfie \
  --query 'SecurityGroups[].IpPermissions' --output json

# egress に UDP/TCP 7844 の両方があること（落とすと Tunnel が張れず全断する）
aws ec2 describe-security-groups --filters Name=tag:Project,Values=shelfie \
  --query 'SecurityGroups[].IpPermissionsEgress[].[IpProtocol,FromPort]' --output text

INSTANCE_ID="$(aws cloudformation describe-stacks --stack-name shelfie-prod-workload \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' --output text)"

# IMDSv2 が必須になっていること
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[].Instances[].MetadataOptions.HttpTokens' --output text

# SSH 鍵を使わずにシェルに入れること
aws ssm start-session --target "$INSTANCE_ID"
```

シェルに入ったら、user-data の結果を確認する。

```bash
ls -l /opt/shelfie/.initialized      # 無ければ user-data が途中で死んでいる
sudo tail -50 /var/log/cloud-init-output.log
free -h                              # スワップ 2GB
systemctl is-active cloudflared && systemctl is-enabled cloudflared
```

> **CFN は user-data の失敗を検知しない。** スクリプトが死んでもスタックは `CREATE_COMPLETE` になる。
> `/opt/shelfie/.initialized` の有無が唯一の判定材料。

最後に公開経路を確認する。

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://api.shelfie.jp/up
```

- **502** … Tunnel は生きていて、アプリのコンテナがまだ無い状態。**この時点では正常**
- **1033** … cloudflared が Cloudflare に接続できていない。egress の 7844 とトークンを疑う

## 変更するとき

テンプレートは git で管理し、**手でコンソールから変更しない。**
コンソールで変えるとスタックとの差分（ドリフト）が生まれ、次の適用で巻き戻る。

```bash
aws cloudformation detect-stack-drift --stack-name shelfie-prod-budget
```

## 関連ドキュメント

- [ADR 010: ホスティング先](../docs/decisions/010-hosting.md) — 構成とコストの根拠
- ADR 011: 本番デプロイ方式 — Kamal を使わない理由（**未作成**）
- ADR 012: AWS アカウント構成 — アカウントを分ける理由（**未作成**）

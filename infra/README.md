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
| `cloudformation/cfn-shelfie-workload.yaml` | **ワークロードと同じ** | VPC / SG / IAM / OIDC / EC2 / SSM パラメータ（**未作成**） |

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

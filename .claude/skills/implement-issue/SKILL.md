---
name: implement-issue
description: issue を1件、実装して PR を作るところまで自走するスキル。/implement-issue #NN で起動する。issue の完了条件・触ってよいファイルを契約として読み、レイヤー単位で実装し、gate-verifier で検証して PR を作る。新機能・既存改修・削除のいずれにも使う。
---

# implement-issue スキル

issue を1件、**PR を作るところまで**自走するスキル。ループの**行動フェーズ**を担当する。

着手する issue は `/loop-triage` が選ぶ。引数で issue 番号が渡されればそれを扱う。

`.claude/rules/loop-policy.md` に従うこと。特に**停止条件**と**差分の最小性**。

---

## Step 1: issue を読む（契約の確定）

```bash
gh issue view {number}
```

以下を**契約**として抽出する。以降のすべての判断はこの契約に照らして行う。

| 抽出するもの | 使い方 |
|---|---|
| 変更の種類 | Step 5〜8 のどのレイヤーを実施するか決める |
| やること | 何を作る・変える・消すか。完了条件だけでは意図が分からない |
| 完了条件 | Step 10 の検証で、1つずつ満たしたか確認する |
| 触ってよいファイル | この外に手を出さない |
| 触ってはいけないファイル | 変更が必要になったら停止する |
| エスカレーション条件 | 該当したら停止する。**ここに無い迷いは自分で判断して進む** |

いずれかが欠けている場合は**着手しない**。issue に不足を1コメントして終了する
（`/loop-triage` のプレフライト検査で弾かれているはずだが、直接起動された場合の保険）。

**`.claude/state/loop.md` は「触ってよいファイル」に書かれていなくても更新してよい。**
ループの記帳であって issue の成果物ではないため、どの契約でも例外
（`.claude/rules/loop-policy.md` §2）。Step 13 で feature ブランチにコミットする。

---

## Step 2: 作業ブランチを作る

```bash
git status --short          # クリーンであることを確認
git checkout develop
git pull origin develop --ff-only
git checkout -b "feature/issue#{number}"
```

既に対応するブランチがある場合はそれに切り替える（`.claude/state/loop.md` の「対応中」を確認）。

---

## Step 3: 仕様と既存コードを確認する

### 必ず読むもの

- `docs/development/implementation-guidelines.md` — アーキテクチャ制約・禁止事項・命名ルール
- `docs/development/directory.md` — 各層の責務・呼び出し関係・判断基準

**実装の作法はこのスキルに書かない。上記が単一の情報源。**
ここにコピーを作ると、docs と食い違ったときに高い遵守率のまま間違いを実行することになる。

### API に関わる issue の場合

**仕様の正は issue 本文。** 起票の段階で確定している前提で読む。
`docs/api/**` は実装済み API の仕様書であり、**新規・変更のときは issue が先、docs は後**。

既存 API を変更する issue なら、現行の仕様書も読んで差分を把握する。

| エンドポイント | ドキュメントディレクトリ |
|---|---|
| `/v1/auth/*` | `docs/api/auth/` |
| `/v1/users/*` | `docs/api/users/` |
| `/v1/me` 系 | `docs/api/users/` または `docs/api/user_books/` |
| `/v1/books/*` | `docs/api/books/` |
| `/v1/users/:username/books/*` または `/v1/me/books/*` | `docs/api/user_books/` |

ファイル名はアクション（create / show / index / update / destroy / login / logout / refresh など）に対応する。
`/v1` 外のエンドポイントはパスに対応するディレクトリを作る（例: `/auth/:provider` → `docs/api/oauth/`）。

**該当する `docs/api/**` を同じ PR で更新する。** 新規なら `docs/api/template.md` の
節構成（`## 概要` / `## リクエスト` / `## 処理詳細` / `## レスポンス`）に従って作成する。
エンドポイントを増減させたときは `docs/api/endpoints.md` の一覧も更新する。

「実装だけして docs は別 PR」はしない。仕様書と実装がずれた状態を作らないため。

**issue 本文に仕様が無い場合は実装しない。** issue にその旨をコメントして停止する。
仕様を自分で決めるのは担当範囲外（`.claude/rules/loop-policy.md`）。

### 既存ファイルの確認

- 対象の Controller / Service / Model / Serializer が既に存在するか
- `config/routes.rb` に対象のルートが定義されているか
- 対象の Migration が既に適用されているか（`db/schema.rb` を確認）

---

## Step 4: 実装計画を完了条件と照合する

計画を立て、**issue の完了条件と1対1で対応しているか自己照合する**。

```
## 実装計画

### 完了条件との対応
| issue の完了条件 | 満たす手段 |
|---|---|
| {完了条件1} | {どのファイルの変更で満たすか} |

### 作成・変更するファイル
**新規作成**: ...
**変更**: ...

### 触ってよいファイルの範囲に収まっているか
{issue の「触ってよいファイル」と照合した結果}
```

**対応の付かない完了条件があるか、範囲外のファイルが必要な場合は停止する**（Step 11 へ）。

対応が付いたらそのまま Step 5 へ進む。**承認は待たない。**

---

## Step 5〜8: 実装

issue の性質に応じて、必要なレイヤーだけ実施する。
新規 API 実装なら 5→6→7→8 の順、削除やリファクタなら該当するものだけ。

**この順序にする理由**: spec を先に書くと、実装の都合に引きずられずに仕様を固定できる。

### Step 5: Request spec（rswag）

- `swagger_helper` を require する
- `tags` はエンドポイント一覧の「グループ名」に合わせる（例: `"認証系"`, `"ユーザー系"`）
- `security [ Bearer: [] ]` は認証が必要なエンドポイントのみ
- アクセストークンの検証は `allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })` でスタブ。
  実例は `spec/requests/v1/me_spec.rb`
- Cookie 経由のトークン（`signup_token` / `refresh_token`）は**スタブせず本物を発行する**
- `purpose:` の扱いと全パターンは `docs/development/testing.md` の「認証のテスト」を見る
- 外部API呼び出しは必ずモックする
- `schema` には `$ref` でコンポーネントを参照する（定義がない場合はインラインで書く）

### Step 6: Migration / Model

- Migration はすでに適用済みのカラムがあれば追加 Migration のみ書く
- **既存の `db/migrate/*.rb` は編集しない**（PreToolUse フックがブロックする）
- バリデーションのルールは仕様書に記載されたものを忠実に実装する
- バリデーションエラーメッセージは `config/locales/` の i18n で管理する（`docs/development/validation.md`）
- `app/constants/` のエラーコードと照合する（`docs/development/constants.md`）
- バリデーションが複雑な場合は `spec/models/xxx_spec.rb` も作成する

### Step 7: Service

- クラス名: `{Namespace}::{Action}Service`（例: `Users::CreateService`）
- `call` メソッドに処理を集約する
- 保存は `!` 付きメソッドを使う（`save!`, `create!`）→ `ActiveRecord::RecordInvalid` を ErrorHandler に任せる
- Service が Service を呼ぶのは禁止
- 外部API通信は `lib/clients/` のクライアントクラスに委譲する
- `spec/services/xxx/create_service_spec.rb` を作成する（正常系・異常系）

### Step 8: Controller + Routes

- `V1::BaseController` を継承する
- アクション内では Service を1つだけ呼ぶ
- `render json: { ... }, status: :xxx` でレスポンスを返す
- 認証が必要なエンドポイントは `before_action :authenticate_user!` を設定する
- Controller に `rescue_from` を書かない（`ErrorHandler` Concern に任せる）
- ルートは `config/routes.rb` に追加する

---

## Step 9: swagger.yaml の生成

API を追加・変更した場合のみ。

```bash
docker compose exec web bundle exec rails rswag:specs:swaggerize
```

---

## Step 10: 検証

### 10-1. 機械判定ゲート

`gate-verifier` サブエージェントを起動する。CI と同じ5ゲート（rspec / rubocop / steep /
brakeman / bundler-audit）を通しで判定させる。

**自分で「たぶん通る」と判断しない。** 合否は `gate-verifier` が出す。

不合格の場合は修正して再度起動する。修正には `test-fixer`（テスト）や
`lint-fixer`（RuboCop）を使ってよい。

### 10-2. 規約レビュー

ゲートが合格したら `guideline-reviewer` サブエージェントを起動する。

- 🔴 必須 の指摘 → 修正して 10-1 からやり直す
- 🟡 推奨 の指摘 → 記録するだけで続行してよい

### 10-3. 完了条件の照合

issue の完了条件を1つずつ、**実行したコマンドと出力で**満たしたことを確認する。

### 試行上限

**10-1 → 10-2 の往復は最大3回。** 3回で合格しなければ Step 11 へ。

---

## Step 11: 停止する場合

`.claude/rules/loop-policy.md`「4. 停止条件」に該当したら、ここで止まる。

**作業が残っているので draft PR を出す。** issue コメントだけで終わるとブランチが
放置され、次のループが拾えなくなる。

```bash
git add -A && git commit -m "wip: {issue のタイトル}"
git push -u origin "feature/issue#{number}"
gh pr create --draft --base develop \
  --title "WIP: {issue のタイトル} (#{number})" \
  --body "{下記のフォーマット}"
```

draft PR の本文に必ず書くもの:

```markdown
## 状況
issue #NN の実装中に停止しました。

## ゲートの結果
{gate-verifier の出力をそのまま貼る}

## 止まった分類
契約の欠陥 / 実行の失敗 のどちらか

## 試行回数
N 回

## 判断をお願いしたいこと
A: {選択肢A}
B: {選択肢B}
```

**「どうしますか」と書かない。選択肢の形で1つだけ聞く。**

issue には `blocked` を提案するコメントを1件だけ残す。**ラベルは付けない。**

---

## Step 12: PR を作る

すべてのゲートが合格し、完了条件を満たしたら PR を作る。

```bash
git add -A && git commit -m "{prefix}: {issue のタイトル}"
git push -u origin "feature/issue#{number}"
gh pr create --base develop --title "{issue のタイトル} (#{number})" --body "{本文}"
```

PR 本文に含めるもの: 対応した issue（`Closes #NN`）、変更の概要、
`gate-verifier` の結果、`guideline-reviewer` の 🟡 推奨 指摘（あれば）。

**マージはしない**（`settings.json` の deny で禁止されている）。

---

## Step 13: 状態を書き戻す

`.claude/state/loop.md` を更新し、**feature ブランチにコミットして PR に含める**。

- 「対応中」から「完了（直近5件）」へ移す（PR を作った場合）
- 停止した場合は「人間待ち（blocked）」と「試行回数」に記録する
- 最終実行日を更新する（`date +%F` で取得。推測で書かない）

state を git 追跡下に置いているのは、Routines やクラウドセッションが
**fresh clone で動く**ため。追跡外にすると毎回空の状態から始まり、
「エージェントは忘れるが、リポジトリは忘れない」が成立しなくなる。

そのため**どの PR にも `.claude/state/loop.md` の差分が1件含まれる**。これは正常。

---

## 進め方のルール

- **承認を待たない。** 停止条件に当たらない限り PR まで進む
- **仕様書に記載のない動作を勝手に決めない。** 記載がないこと自体が停止条件
- **issue の「触ってよいファイル」の外に手を出さない。** 「ついでに直す」はしない
- **1周につき1 issue。** PR を作ったら終了する

## 参照ドキュメント

- `docs/development/implementation-guidelines.md` — アーキテクチャ制約・禁止事項・命名ルール
- `docs/development/directory.md` — どのレイヤーに何を書くか
- `docs/development/testing.md` — spec の書き方パターン
- `docs/development/validation.md` — バリデーションとエラーハンドリング
- `docs/development/constants.md` — 定数・エラーコード管理
- `docs/architecture/auth.md` — 認証フロー（認証系APIの実装時）

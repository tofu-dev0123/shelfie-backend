---
name: implement-api
description: APIを実装するスキル。/implement-api コマンドで起動する。エンドポイント一覧を表示してユーザーに実装するAPIを選択させ、仕様書を参照しながらRequest spec → Migration/Model → Service → Controller の順でレイヤー単位に実装を進める。各フェーズで実装内容をユーザーに提示して承認を得てから実装する。
---

# implement-api スキル

APIを1本、順を追って実装するスキル。各フェーズで必ず止まってユーザーと確認してから進む。

---

## Step 1: エンドポイント選択

`docs/api/endpoints.md` を読み込み、エンドポイント一覧をグループ別に表示してユーザーに選択させる。

```
どのAPIを実装しますか？

### 認証系
1. POST /v1/auth/login - ログインAPI
2. ...

番号で選択してください。
```

---

## Step 2: 仕様書の読み込み

選択されたエンドポイントに対応する仕様書ファイルを読み込む。

### ドキュメントパスのマッピング規則

| エンドポイント | ドキュメントディレクトリ |
|---|---|
| `/v1/auth/*` | `docs/api/auth/` |
| `/v1/users/*` | `docs/api/users/` |
| `/v1/me` 系 | `docs/api/users/` または `docs/api/user_books/` |
| `/v1/books/*` | `docs/api/books/` |
| `/v1/users/:username/books/*` または `/v1/me/books/*` | `docs/api/user_books/` |
| `/v1/me/follows/*` または `/v1/users/:username/follow*` | `docs/api/follows/` |
| `/v1/me/likes/*` | `docs/api/likes/` |
| `/v1/tags` または `/v1/me/tag_follows/*` | `docs/api/tags/` または `docs/api/tag_follows/` |
| `/v1/feed*` | `docs/api/feed/` |

ファイル名はアクション（create / show / index / update / destroy / login / logout / refresh など）に対応する。

---

## Step 3: 既存ファイルの確認

実装を始める前に、以下を確認する。

- 対象の Controller / Service / Model / Serializer が既に存在するか
- routes.rb に対象のルートが定義されているか
- 対象の Migration が既に適用されているか（`db/schema.rb` を確認）

確認結果をユーザーに報告し、新規作成が必要なファイルを明示する。

---

## Step 4: 実装計画の提示と承認

仕様書と既存ファイルの確認結果をもとに、実装計画をユーザーに提示する。

提示フォーマット：

```
## [API名] の実装計画

### 作成・変更するファイル

**新規作成**
- spec/requests/v1/xxx_spec.rb
- db/migrate/YYYYMMDDXXXXXX_create_xxx.rb（必要な場合）
- app/models/xxx.rb（必要な場合）
- app/services/xxx/create_service.rb
- app/controllers/v1/xxx_controller.rb

**変更**
- config/routes.rb

### 実装の流れ

1. Request spec（rswag）
2. Migration / Model
3. Service
4. Controller + Routes

### 注意点・懸念点

[仕様書を読んで気になった点があれば明記する]

この計画で進めてよいですか？
```

ユーザーが承認したら Step 5 へ進む。

---

## Step 5: Request spec の実装

rswag DSL で Request spec を書く。

### 実装前に確認すること

実装内容をユーザーに提示してから書く：

```
## Request spec の実装計画

**ファイル**: spec/requests/v1/xxx_spec.rb

**カバーするテストケース**
- 正常系: [ステータスコードとシナリオ]
- 異常系: [ステータスコードとシナリオ]

**認証モック**: [Clerk JWT の検証モックについて]

このテストケースで問題ありませんか？
```

### 実装パターン

- `swagger_helper` を require する
- `tags` はエンドポイント一覧の「グループ名」に合わせる（例: `"認証系"`, `"ユーザー系"`）
- `security [ Bearer: [] ]` は認証が必要なエンドポイントのみ
- Clerk JWT の検証は `allow(Clerk::Token).to receive(:decode).and_return(...)` でスタブ
- 外部API呼び出しは必ずモックする
- `schema` には `$ref` でコンポーネントを参照する（定義がない場合はインラインで書く）

### 実装後の確認

コードを提示して、ユーザーに確認を求める：

```
Request spec を書きました。

[コードを表示]

確認が取れたら次のフェーズ（Migration / Model）に進みます。
```

---

## Step 6: Migration / Model の実装

### 実装前に確認すること

```
## Migration / Model の実装計画

**Migration**
- テーブル名: xxx
- カラム: [カラム名・型・制約の一覧]
- インデックス: [インデックスの一覧]

**Model**
- バリデーション: [バリデーションの一覧]
- アソシエーション: [アソシエーションの一覧]
- スコープ: [あれば]

この設計で問題ありませんか？
```

### 実装パターン

- Migration はすでに適用済みのカラムがあれば追加 Migration のみ書く
- バリデーションのルールは仕様書に記載されたものを忠実に実装する
- バリデーションエラーメッセージは `config/locales/` の i18n で管理する（`docs/development/validation.md` 参照）
- `app/constants/` のエラーコードと照合する（`docs/development/constants.md` 参照）

### Model spec も必要な場合

バリデーションが複雑な場合は `spec/models/xxx_spec.rb` も作成する。

### 実装後の確認

コードを提示して確認を求める。

---

## Step 7: Service の実装

### 実装前に確認すること

```
## Service の実装計画

**ファイル**: app/services/xxx/create_service.rb

**処理フロー**
1. [処理ステップを順番に記載]
2. ...

**発生しうる例外とエラーコード**
- [例外クラス] → [エラーコード]

この設計で問題ありませんか？
```

### 実装パターン

- クラス名: `{Namespace}::{Action}Service`（例: `Users::CreateService`）
- `call` メソッドに処理を集約する
- 保存は `!` 付きメソッドを使う（`save!`, `create!`）→ `ActiveRecord::RecordInvalid` を ErrorHandler に任せる
- Service が Service を呼ぶのは禁止
- 外部API通信は `lib/clients/` のクライアントクラスに委譲する

### Service spec も書く

`spec/services/xxx/create_service_spec.rb` を作成する。正常系と異常系をカバーする。

### 実装後の確認

コードを提示して確認を求める。

---

## Step 8: Controller の実装

### 実装前に確認すること

```
## Controller の実装計画

**ファイル**: app/controllers/v1/xxx_controller.rb

**Routes**
- [HTTPメソッド] [パス] → [コントローラー#アクション]

**Strong Parameters**
- [パラメーターの一覧]

**認証**: [必要 / 不要 / 条件付き]

この設計で問題ありませんか？
```

### 実装パターン

- `V1::BaseController` を継承する
- アクション内では Service を1つだけ呼ぶ
- `render json: { ... }, status: :xxx` でレスポンスを返す
- 認証が必要なエンドポイントは `before_action :authenticate_user!` を設定する
- Controller には rescue_from を書かない（`ErrorHandler` Concern に任せる）
- ルートは `config/routes.rb` に追加する

### 実装後の確認

コードを提示して確認を求める。

---

## Step 9: テスト実行

test-runner サブエージェントを起動する。

```
テストを実行します。test-runner サブエージェントを起動します。

対象ファイル:
- spec/requests/v1/xxx_spec.rb
- spec/models/xxx_spec.rb（作成した場合）
- spec/services/xxx/create_service_spec.rb（作成した場合）
```

テストが失敗した場合は原因を調査して修正し、再度実行する。

---

## Step 10: swagger.yaml の生成

テストが全件パスしたら swagger.yaml を生成する。

```bash
bundle exec rails rswag:specs:swaggerize
```

生成後、ユーザーに報告する。

---

## Step 11: コードチェック

code-checker サブエージェントを起動する（RuboCop + Steep）。

指摘があれば修正する。

---

## Step 12: レビュー

reviewer サブエージェントを起動する。

指摘があれば修正して Step 9 に戻る。指摘がなければ完了。

---

## 各フェーズの進め方ルール

- **必ず実装前に計画を提示して確認を取る**。承認なしにファイルを作成しない。
- ユーザーが「OK」「進めて」と言ったら次へ進む。
- 迷いが生じた場合（仕様書に記載がない・既存コードと矛盾する）はユーザーに確認する。
- 仕様書に記載のない動作は勝手に決めず、必ず確認する。

## 参照ドキュメント

実装中に参照するドキュメント：

- `docs/development/directory.md` — どのレイヤーに何を書くか
- `docs/development/testing.md` — spec の書き方パターン
- `docs/development/validation.md` — バリデーションとエラーハンドリング
- `docs/development/constants.md` — 定数・エラーコード管理
- `docs/architecture/auth.md` — 認証フロー（認証系APIの実装時）

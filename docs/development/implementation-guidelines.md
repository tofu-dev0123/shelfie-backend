# 実装ガイドライン

## 実装フロー

役割単位（Service・Controller・Model など）で順に実装する。

### チェックリスト

```
□ 1. 既存ファイルを確認する（同じ役割のファイルが既にないか）
□ 2. どのレイヤーに書くか判断する → docs/development/directory.md 参照
□ 3. spec を書く
     - Request spec は rswag DSL で書く（テスト兼 Swagger ドキュメント）
     - Model / Service spec は通常の RSpec で書く
□ 4. 実装を書く
□ 5. テストが落ちていれば test-fixer を起動して直す
□ 6. swagger.yaml を生成する（API を追加・変更した場合）
     docker compose exec web bundle exec rails rswag:specs:swaggerize
□ 7. lint が落ちていれば lint-fixer を起動して直す（RuboCop 自動修正 + Steep）
□ 8. gate-verifier を起動して合否を判定させる（CI と同じ5ゲート）
□ 9. 合格 → guideline-reviewer を起動
□10. 🔴 必須 の指摘あり → 5. に戻る（往復は最大3回）
     指摘なし / 🟡 推奨 のみ → 完了
```

サブエージェントの定義 → `.claude/agents/`

**「直す者」と「判定する者」を分けている。**
`test-fixer` と `lint-fixer` はファイルを書き換えるため、合否の判定はしない。
機械判定の合否を出すのは `gate-verifier` だけで、このエージェントは実装ツールを持たない。

| エージェント | 層 | 役割 |
|---|---|---|
| `test-fixer` | 直す者 | spec をパスさせる（最大3回） |
| `lint-fixer` | 直す者 | RuboCop の自動修正 + Steep の検出 |
| `gate-verifier` | 判定する者 | CI と同じ5ゲートを通しで判定。実装しない |
| `guideline-reviewer` | 判定する者 | 規約との照合。ファイルを修正しない |

`gate-verifier` が実行する5ゲートは `.github/workflows/ci.yml` と同じ。
rspec / rubocop / steep / brakeman / bundler-audit のすべてが通って初めて合格。

無人ループでこのフローを回す場合の停止条件 → `.claude/rules/loop-policy.md`

---

## アーキテクチャ制約

詳細 → [docs/development/directory.md](./directory.md)

| レイヤー | やること | やらないこと |
|---|---|---|
| Controller | Service を1つ呼んで render | ビジネスロジック・Model の直接参照 |
| Service | 1操作1クラス、ビジネスロジック | Service が Service を呼ぶ |
| Model | バリデーション・アソシエーション・スコープ | ビジネスロジック |
| Query Object | 複数テーブルをまたぐクエリ | ビジネスロジック |
| Serializer | `as_json` で JSON 組み立て | gem 使用 |
| Client | 外部APIとの通信のみ | ビジネスロジック |

**認証：**
- `v1/me/` 配下 → 全アクション認証必須
- それ以外 → 認証不要（`GET /v1/books/search` / `GET /v1/books/:isbn` のみ例外で認証必須）

**エラーハンドリング：**
- `ErrorHandler` Concern に集約（BaseController に直書きしない）

---

## 禁止事項

- Controller にビジネスロジックを書く
- Controller から直接 Model を参照する（必ず Service を経由する）
- Service が Service を呼ぶ
- Service に Model のバリデーションルールを重複して書く（`save!` / `update!` に任せる）
- Serializer に gem を使う（Blueprinter 等）
- 認証に Devise を使う
- マジックナンバー・文字列リテラルの直書き（`app/constants/` を使う）
- 複数テーブルをまたぐクエリを Model のスコープに書く（Query Object に切り出す）
- `ErrorHandler` を通さず Controller に `rescue_from` を直書きする
- ユーザーの承認なしにファイルの新規作成・削除を行う

---

## 命名ルール

Rails 標準（ファイル名・クラス名・メソッド名等）は RuboCop に委ねる。

| 対象 | 規約 | 例 |
|---|---|---|
| Service クラス | `{Action}Service` | `Auth::LoginService` |
| Serializer クラス | `{Resource}Serializer` | `UserSerializer` |
| Query Object クラス | `{Resource}Query` | `BookReadersQuery` |
| spec ファイル | ソースのパスをミラー | `spec/services/auth/login_service_spec.rb` |
| Request spec ファイル | `spec/requests/v1/` 配下 | `spec/requests/v1/users_spec.rb` |

---

## ログ規約

詳細 → [docs/development/logging.md](./logging.md)

**実装箇所：**
- Controller のアクション先頭に `debug` ログを入れる
- Service の正常終了時に `info` ログを入れる
- ErrorHandler のエラーハンドラに `warn` / `error` ログを入れる

---

## テスト規約

詳細 → [docs/development/testing.md](./testing.md)

---

## コメント規約

コードで表現できない **why（なぜそう書くか）** を日本語で記載する。
what（何をしているか）はコードで読めるため書かない。

**書く場所：**
- Service・Constants に積極的に書く
- Controller にコメントが増えてきたらビジネスロジックが漏れているサイン

**書くタイミング（以下に該当したら書く）：**
- 仕様・要件に基づく制約がある
- 直感に反する実装をしている
- 定数の意味・単位・由来が自明でない
- 意図的な例外処理をしている

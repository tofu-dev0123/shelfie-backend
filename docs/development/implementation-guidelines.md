# 実装ガイドライン

## 実装フロー

役割単位（Service・Controller・Model など）で順に実装する。

### チェックリスト

```
□ 1. 既存ファイルを確認する（同じ役割のファイルが既にないか）
□ 2. どのレイヤーに書くか判断する → docs/development/directory.md 参照
□ 3. spec を書く
□ 4. 実装を書く
□ 5. テスト実行サブエージェントを起動
□ 6. パス → レビューサブエージェントを起動
□ 7. 指摘なし → 完了 / 指摘あり → 5. に戻る
```

### テスト実行サブエージェント

| 項目 | 内容 |
|---|---|
| スコープ | 書いたファイルに対応する spec のみ（ユニットテスト） |
| 動作 | spec 実行 → 失敗時は修正して再実行（最大 3 回）をサブエージェント内で完結 |
| 失敗時 | エラーと原因の考察をユーザーに報告して停止 |
| メインへの返却 | パス or 失敗サマリーのみ |

### レビューサブエージェント

仕様は別途定義。

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
- それ以外 → 認証不要（`/v1/feed` のみ例外）

**エラーハンドリング：**
- `ErrorHandler` Concern に集約（BaseController に直書きしない）

---

## 禁止事項

- Controller にビジネスロジックを書く
- Controller から直接 Model を参照する（必ず Service を経由する）
- Service が Service を呼ぶ
- Service にバリデーションロジックを書く
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
| Query Object クラス | `{Resource}Query` | `FeedQuery` |
| spec ファイル | ソースのパスをミラー | `spec/services/auth/login_service_spec.rb` |

---

## テスト規約

詳細 → [docs/development/testing.md](./testing.md)

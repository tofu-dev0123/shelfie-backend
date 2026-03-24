# API 設計方針

## ベースURL

```
/v1
```

---

## レスポンス形式

### 単一リソース

エンベロープなしのフラット形式で返します。

```json
// GET /v1/users/:username
{
  "id": 1,
  "username": "komusan",
  "nickname": "コムさん",
  "bio": "..."
}
```

### リスト

`items`（データ配列）と `pagination`（ページネーション情報）を並列で返します。

```json
{
  "items": [
    { "id": 1, ... },
    { "id": 2, ... }
  ],
  "pagination": {
    "next_cursor": "eyJpZCI6NDJ9",
    "has_next": true
  }
}
```

---

## ページネーション

全リスト系エンドポイントはカーソルベースのページネーションを採用します。

### リクエストパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `cursor` | string | 不要 | なし（先頭から） | 前回レスポンスの `next_cursor` |
| `limit` | integer | 不要 | 20 | 最大取得件数（上限50） |

### レスポンス（paginationフィールド）

| フィールド | 型 | 説明 |
|---|---|---|
| `next_cursor` | string \| null | 次ページの起点。次ページがない場合は `null` |
| `has_next` | boolean | 次ページが存在するか |

`next_cursor` はBase64エンコードされた文字列です（例：`{ "id": 42 }` → `eyJpZCI6NDJ9`）。

### カーソルの基準カラム

| エンドポイント | カーソルの基準 |
|---|---|
| `GET /v1/feed` | `created_at` + `id` |
| `GET /v1/users/:username/books` | `created_at` + `id` |
| `GET /v1/users/:username/followers` | `id` |
| `GET /v1/users/:username/following` | `id` |
| `GET /v1/books/:google_books_id`（読んだユーザー） | `id` |

> `created_at` のみをカーソルにすると同一時刻レコードで重複・抜けが発生するため、`id` を組み合わせて一意性を保証します。

---

## エラーレスポンス

### 形式

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "不正なリクエストです。",
    "details": [
      { "field": "username", "message": "すでに使用されています" }
    ]
  }
}
```

| フィールド | 説明 |
|---|---|
| `code` | フロント側でハンドリングするための機械向け識別子 |
| `message` | デバッグ用の人間向けメッセージ（ユーザーへの直接表示は非推奨） |
| `details` | バリデーションエラー時のフィールド別エラー情報の配列（省略可）。各要素は `field`（フィールド名）と `message`（エラーメッセージ）を持つ |

### エラーコード一覧

| code | HTTPステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | 未認証・トークン期限切れ |
| `FORBIDDEN` | 403 | 他人のリソースを操作しようとした |
| `NOT_FOUND` | 404 | リソースが存在しない |
| `VALIDATION_ERROR` | 422 | 入力値の検証エラー |
| `CONFLICT` | 409 | 重複（いいね済み・フォロー済みなど） |
| `INTERNAL_SERVER_ERROR` | 500 | サーバー内部エラー |

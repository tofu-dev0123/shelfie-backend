# POST /v1/me/books

## 概要

書籍を本棚に追加する。Books テーブルに未登録の場合は同時に登録する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### ボディ

```json
{
  "google_books_id": "xxxxxxxx",
  "content": "とても良い本でした",
  "tags": ["Go", "Architecture"],
  "purchase_links": [
    "https://www.amazon.co.jp/..."
  ]
}
```

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `google_books_id` | string | 必須 | |
| `content` | string | 任意 | 最大1000文字 |
| `tags` | array | 任意 | 最大5件。存在するタグ名のみ有効 |
| `purchase_links` | array | 任意 | URL形式、最大3件 |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `google_books_id` で Books テーブルを検索し、未登録なら Google Books API から取得して登録
3. 既に同じ書籍を登録済みでないか確認
4. `user_books` レコードを作成
5. `tags` があれば `user_book_tags` レコードを作成
6. `purchase_links` があれば `user_book_purchase_links` レコードを作成

## レスポンス

### 成功

```json
// 201 Created
{
  "message": "登録が完了しました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `NOT_FOUND` | 404 | Google Books API に書籍が存在しない |
| `CONFLICT` | 409 | すでに同じ書籍を登録済み |
| `VALIDATION_ERROR` | 422 | バリデーション違反 |

# DELETE /v1/me/books/:google_books_id

## 概要

本棚から投稿を削除する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:google_books_id` | string | Google Books API の書籍ID |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `google_books_id` → `book_id` を取得し、ログインユーザーの `user_books` レコードを検索
3. `user_books` レコードを削除（関連する `user_book_purchase_links` / `likes` も CASCADE削除）

## レスポンス

### 成功

```json
// 200 OK
{
  "message": "削除が完了しました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `NOT_FOUND` | 404 | 投稿が存在しない |

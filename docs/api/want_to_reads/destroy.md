# DELETE /v1/me/want_to_reads/:google_books_id

## 概要

指定した書籍を自分の読みたいリストから削除する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:google_books_id` | string | Google Books API の書籍ID |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `google_books_id` → `book_id` を取得し、ログインユーザーの `want_to_reads` レコードを検索・削除

## レスポンス

### 成功

```json
// 200 OK
{
  "message": "読みたいリストから削除しました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `NOT_FOUND` | 404 | 読みたいリストに該当書籍が存在しない |

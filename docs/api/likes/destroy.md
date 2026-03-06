# DELETE /v1/me/likes/:username/:google_books_id

## 概要

指定した投稿のいいねを取り消す。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:username` | string | 投稿したユーザーの username |
| `:google_books_id` | string | Google Books API の書籍ID |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `username` + `google_books_id` で `user_books` レコードを検索
3. ログインユーザーの `likes` レコードを検索・削除

## レスポンス

### 成功

```json
// 200 OK
{
  "message": "いいねを取り消しました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `NOT_FOUND` | 404 | 投稿が存在しない・いいねしていない |

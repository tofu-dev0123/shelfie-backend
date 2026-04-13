# DELETE /v1/me/books/:isbn

## 概要

本棚から投稿を削除する。冪等性あり（isbn に対応する book が存在しない場合・user_books が存在しない場合も 200 を返す）。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:isbn` | string | ISBNコード |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `isbn` → `book_id` を取得し、ログインユーザーの `user_books` レコードを検索
3. `user_books` レコードを削除（関連する `user_book_purchase_links` も CASCADE削除）

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
| `VALIDATION_ERROR` | 422 | isbn が13桁の数字でない |

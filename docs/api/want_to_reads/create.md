# POST /v1/me/want_to_reads/:google_books_id

## 概要

指定した書籍を自分の読みたいリストに追加する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:google_books_id` | string | Google Books API の書籍ID |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `google_books_id` で Books テーブルを検索し、未登録なら Google Books API から取得して登録
3. 既に読みたいリストに追加済みでないか確認
4. `want_to_reads` レコードを作成

## レスポンス

### 成功

```json
// 201 Created
{
  "message": "読みたいリストに追加しました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `NOT_FOUND` | 404 | Google Books API に書籍が存在しない |
| `CONFLICT` | 409 | 既に読みたいリストに追加済み |

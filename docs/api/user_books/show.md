# GET /v1/users/:username/books/:google_books_id

## 概要

指定したユーザーの特定書籍の投稿詳細を取得する。

## リクエスト

### 認証

不要

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:username` | string | 投稿したユーザーの username |
| `:google_books_id` | string | Google Books API の書籍ID |

## 処理詳細

1. `username` → `user_id`、`google_books_id` → `book_id` を取得
2. `user_books` から該当レコードを検索
3. 書籍情報・投稿者情報・投稿内容・いいね数・購入リンクを返す

## レスポンス

### 成功

```json
// 200 OK
{
  "id": 1,
  "status": "completed",
  "content": "とても良い本でした",
  "likes_count": 5,
  "tags": ["Go", "Architecture"],
  "created_at": "2026-03-05T00:00:00Z",
  "book": {
    "google_books_id": "xxxxxxxx",
    "title": "リーダブルコード",
    "authors": ["Dustin Boswell", "Trevor Foucher"],
    "thumbnail_url": "https://..."
  },
  "user": {
    "username": "komusan",
    "nickname": "コムさん",
    "avatar_url": null
  },
  "purchase_links": [
    "https://www.amazon.co.jp/..."
  ]
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `NOT_FOUND` | 404 | ユーザーまたは投稿が存在しない |

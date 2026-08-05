# GET /v1/users/:username/books/:isbn

## 概要

指定したユーザーの特定書籍の投稿詳細を取得する。

## リクエスト

### 認証

不要

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:username` | string | 投稿したユーザーの username |
| `:isbn` | string | ISBNコード |

## 処理詳細

1. `username` → `user_id`、`isbn` → `book_id` を取得
2. `user_books` から該当レコードを検索
3. 書籍情報・投稿者情報・投稿内容を返す

## レスポンス

### 成功

```json
// 200 OK
{
  "id": 1,
  "content": "とても良い本でした",
  "created_at": "2026-03-05T00:00:00Z",
  "updated_at": "2026-03-06T00:00:00Z",
  "book": {
    "isbn": "9784873116068",
    "title": "リーダブルコード",
    "authors": ["Dustin Boswell", "Trevor Foucher"],
    "thumbnail_url": "https://..."
  },
  "user": {
    "username": "komusan",
    "nickname": "コムさん"
  }
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `NOT_FOUND` | 404 | ユーザーまたは投稿が存在しない |

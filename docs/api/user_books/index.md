# GET /v1/users/:username/books

## 概要

指定したユーザーの本棚一覧を取得する。

## リクエスト

### 認証

不要

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:username` | string | 取得するユーザーの username |

### クエリパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `cursor` | string | 任意 | なし | 前回レスポンスの `next_cursor` |
| `limit` | integer | 任意 | 20 | 最大取得件数（上限50） |

## 処理詳細

1. `username` で User レコードを検索
2. そのユーザーの `user_books` を `created_at DESC` + `id DESC` でカーソルページネーションして取得
3. 書籍情報・投稿内容を合わせて返す

## レスポンス

### 成功

```json
// 200 OK
{
  "items": [
    {
      "id": 1,
      "content": "とても良い本でした",
      "created_at": "2026-03-05T00:00:00Z",
      "book": {
        "google_books_id": "xxxxxxxx",
        "title": "リーダブルコード",
        "authors": ["Dustin Boswell", "Trevor Foucher"],
        "thumbnail_url": "https://..."
      }
    }
  ],
  "pagination": {
    "next_cursor": "eyJpZCI6NDJ9",
    "has_next": true
  }
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `NOT_FOUND` | 404 | ユーザーが存在しない |

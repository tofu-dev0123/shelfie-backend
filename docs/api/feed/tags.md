# GET /v1/feed/tags

## 概要

タグフォローベースのフィードを取得する。
自分がフォローしているタグが付いた投稿を新着順で返す。

`status = want_to_read` の投稿はフィードに表示しない。

ユーザーフォローベースのフィードは [`GET /v1/feed`](./index.md) を参照。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### クエリパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `cursor` | string | 任意 | なし | 前回レスポンスの `next_cursor` |
| `limit` | integer | 任意 | 20 | 最大取得件数（上限50） |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `tag_follows` からそのユーザーがフォロー中のタグIDを取得
3. `user_book_tags` でそのタグが付いた `user_books` を取得
4. `status = want_to_read` の投稿を除外
5. `created_at DESC` + `id DESC` でカーソルページネーションして返す

## レスポンス

### 成功

```json
// 200 OK
{
  "items": [
    {
      "id": 1,
      "status": "completed",
      "content": "とても良い本でした",
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
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |

# GET /v1/feed

## 概要

ユーザーフォローベースのフィードを取得する。ログイン状態によって返す投稿が異なる。

| 状態 | 挙動 |
|---|---|
| ログイン済み | フォロー中ユーザーの投稿を新着順で返す |
| 未ログイン | 全ユーザーの投稿を新着順で返す（discovery 用途） |

`status = want_to_read` の投稿はフィードに表示しない。

タグフォローベースのフィードは [`GET /v1/feed/tags`](./tags.md) を参照。

## リクエスト

### 認証

任意（`Authorization: Bearer <アクセストークン>`）

### クエリパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `cursor` | string | 任意 | なし | 前回レスポンスの `next_cursor` |
| `limit` | integer | 任意 | 20 | 最大取得件数（上限50） |

## 処理詳細

1. `Authorization` ヘッダーを確認
2. トークンがある場合 → フォロー中ユーザーの `user_books` を取得
3. トークンがない場合 → 全ユーザーの `user_books` を取得
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
        "isbn": "9784873116068",
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

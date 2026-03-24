# GET /v1/me/want_to_reads

## 概要

自分の読みたいリストを取得する。

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
2. ログインユーザーの `want_to_reads` を `created_at DESC` + `id DESC` でカーソルページネーションして取得
3. 書籍情報を合わせて返す

## レスポンス

### 成功

```json
// 200 OK
{
  "items": [
    {
      "google_books_id": "xxxxxxxx",
      "title": "リーダブルコード",
      "authors": ["Dustin Boswell", "Trevor Foucher"],
      "thumbnail_url": "https://..."
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

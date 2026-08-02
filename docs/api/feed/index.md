# GET /v1/feed

## 概要

ユーザーフォローベースのフィードを取得する。ログイン状態によって返す投稿が異なる。

| 状態 | 挙動 |
|---|---|
| ログイン済み | フォロー中ユーザー + 自分の投稿を新着順で返す |
| 未ログイン | 全ユーザーの投稿を新着順で返す（discovery 用途） |

## リクエスト

### 認証

任意。`Authorization` ヘッダーの有無・内容によって挙動が異なる。

| ヘッダー | 挙動 |
|---|---|
| なし | 未ログイン扱い（全ユーザー投稿を返す） |
| 有効なアクセストークン | ログイン扱い（フォロー中ユーザー + 自分の投稿を返す） |
| 無効・期限切れトークン | 401 `UNAUTHORIZED` |

### クエリパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `cursor` | string | 任意 | なし | 前回レスポンスの `next_cursor`。不正な値の場合は 422 を返す |
| `limit` | integer | 任意 | 20 | 最大取得件数（上限50）。`0` 以下はデフォルト値（20）、`50` 超はクランプ |

## 処理詳細

1. `Authorization` ヘッダーを確認
2. ヘッダーあり・トークンが無効／期限切れ → 401 `UNAUTHORIZED`
3. ヘッダーあり・トークンが有効 → フォロー中ユーザー + 自分の `user_books` を取得
4. ヘッダーなし → 全ユーザーの `user_books` を取得
5. `created_at DESC` + `id DESC` でカーソルページネーションして返す
6. 各投稿の `tags` は名前順（昇順）で返す

## レスポンス

### 成功

```json
// 200 OK
{
  "items": [
    {
      "id": 1,
      "content": "とても良い本でした",
      "tags": ["Architecture", "Go"],
      "created_at": "2026-03-05T00:00:00Z",
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
| `VALIDATION_ERROR` | 422 | 不正なカーソル値（デコード失敗・id が整数でない） |

# GET /v1/books/search

## 概要

Google Books API を経由して書籍を検索する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### クエリパラメータ

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `q` | string | 必須 | 検索キーワード（タイトル・著者名など） |
| `cursor` | string | 任意 | 前回レスポンスの `next_cursor`（省略時は先頭から） |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `q` のバリデーション
3. `cursor` をデコードして `start_index` を取得（省略時は 0）
4. Google Books API に `q` / `startIndex` / `maxResults=10` を指定してリクエスト
5. Google Books API のレスポンスから `totalItems` を取得し `has_next` を判定
6. 結果を整形して返す

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
    "next_cursor": "eyJzdGFydEluZGV4IjoxMH0=",
    "has_next": true
  }
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `VALIDATION_ERROR` | 422 | `q` が空 |

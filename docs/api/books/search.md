# GET /v1/books/search

## 概要

Google Books API を経由して書籍を検索する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### クエリパラメータ

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `q` | string | 必須 | 検索キーワード（タイトル・著者名など）。空白トリム後1文字以上・100文字以内 |
| `cursor` | string | 任意 | 前回レスポンスの `next_cursor`（省略時は先頭から）。不正な値は 422 を返す |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `q` のバリデーション（空白トリム後に空・100文字超は 422）
3. `cursor` をデコードして `start_index` を取得（省略時は 0）。デコード失敗は 422
4. Google Books API に `q` / `startIndex` / `maxResults=10` を指定してリクエスト
5. 取得件数が `maxResults(10)` 未満なら `has_next: false`、そうでなければ `true`
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
      "authors": ["Dustin Boswell", "Trevor Foucher"], // 著者不明の場合は []
      "thumbnail_url": "https://..."                   // サムネイルなしの場合は null
    }
  ],
  // 0件の場合は items: [] で 200 を返す
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
| `VALIDATION_ERROR` | 422 | `q` が空・空白のみ・100文字超 |
| `VALIDATION_ERROR` | 422 | `cursor` のデコードに失敗 |
| `EXTERNAL_API_ERROR` | 503 | Google Books API がエラー・タイムアウトを返した |

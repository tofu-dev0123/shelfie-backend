# GET /v1/books/:google_books_id

## 概要

書籍の詳細情報を取得する。

## リクエスト

### 認証

不要

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:google_books_id` | string | Google Books API の書籍ID |

## 処理詳細

1. `google_books_id` で Books テーブルを検索
2. 書籍情報を返す

## レスポンス

### 成功

```json
// 200 OK
{
  "google_books_id": "xxxxxxxx",
  "title": "リーダブルコード",
  "authors": ["Dustin Boswell", "Trevor Foucher"],
  "thumbnail_url": "https://...",
  "isbn": "9784873115658",
  "published_date": "2012-06-23"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `NOT_FOUND` | 404 | 書籍が Books テーブルに存在しない（誰も登録していない） |

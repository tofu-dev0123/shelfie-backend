# PATCH /v1/me/books/:isbn

## 概要

本棚の投稿内容を更新する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:isbn` | string | ISBNコード |

### ボディ

```json
{
  "content": "改めて読み直したら更に良かったです",
  "tags": ["Go", "Architecture"],
  "purchase_links": [
    "https://www.amazon.co.jp/..."
  ]
}
```

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `content` | string | 任意 | 最大1000文字 |
| `tags` | array | 任意 | 最大5件。存在するタグ名のみ有効 |
| `purchase_links` | array | 任意 | URL形式、最大3件 |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `isbn` → `book_id` を取得し、ログインユーザーの `user_books` レコードを検索
3. `content` を更新
4. `tags` は全件置き換えで更新（省略時は変更なし、空配列 `[]` を渡すと全削除）
5. `purchase_links` は全件置き換えで更新（省略時は変更なし、空配列 `[]` を渡すと全削除）

## レスポンス

### 成功

```json
// 200 OK
{
  "message": "更新が完了しました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `NOT_FOUND` | 404 | 投稿が存在しない |
| `VALIDATION_ERROR` | 422 | バリデーション違反 |

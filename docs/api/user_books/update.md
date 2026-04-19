# PUT /v1/me/books/:isbn

## 概要

本棚の投稿内容を更新する。タグは `content` のハッシュタグから再構築する（送信内容で完全置換）。

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
  "content": "改めて読み直したら更に良かったです #Go #アーキテクチャ",
  "purchase_links": [
    "https://www.amazon.co.jp/..."
  ]
}
```

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `content` | string | 必須 | 最大1000文字。中の `#xxx` がタグとして抽出される |
| `purchase_links` | array | 必須 | URL形式、最大3件 |

ハッシュタグ抽出仕様は POST /v1/me/books と同様。1投稿あたり最大5タグ。

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `content` からハッシュタグを抽出
3. `isbn` → `book_id` を取得し、ログインユーザーの `user_books` レコードを検索
4. `content` を送信値で上書き
5. 抽出タグを `Tag.find_or_create_safely!` で取得・生成し、`user_book_tags` を全件置き換え（タグが抽出されなければ全削除。並列リクエストで同名タグが同時作成された場合は `RecordNotUnique` を検知して作成済みレコードを再検索する）
6. `purchase_links` は送信値で全件置き換え（空配列 `[]` で全削除）

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
| `NOT_FOUND` | 404 | 書籍または投稿が存在しない |
| `VALIDATION_ERROR` | 422 | バリデーション違反（`field` に違反フィールド名を含む場合あり） |

```json
// VALIDATION_ERROR レスポンス例
{
  "code": "VALIDATION_ERROR",
  "field": "purchase_links"
}
```

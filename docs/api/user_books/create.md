# POST /v1/me/books

## 概要

書籍を本棚に追加する。Books テーブルに未登録の場合は同時に登録する。
タグは `content` 中の `#xxx` をサーバー側で解析して自動で紐付ける（既存タグは再利用、未登録は新規作成）。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### ボディ

```json
{
  "isbn": "9784873116068",
  "content": "とても良い本でした #Go #アーキテクチャ",
  "purchase_links": [
    "https://www.amazon.co.jp/..."
  ]
}
```

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `isbn` | string | 必須 | 13文字の数字のみ（ISBN-13） |
| `content` | string | 任意 | 最大1000文字。中の `#xxx` がタグとして抽出される |
| `purchase_links` | array | 任意 | URL形式・各URL最大1000文字・最大3件 |

### ハッシュタグ抽出仕様

- 正規表現: `/#([\p{L}\p{N}_]{1,50})/`
- 許容文字: Unicode 文字（日本語含む）・数字・アンダースコア
- 1タグの長さ上限: 50文字
- 重複は自動的にまとめる
- 大文字小文字は区別する（`#SF` と `#sf` は別タグ）
- 1投稿あたり最大5タグ（超過時 422）

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `content` からハッシュタグを抽出
3. `isbn` で Books テーブルを検索し、未登録なら楽天書籍APIから取得して登録
4. 既に同じ書籍を登録済みでないか確認
5. `user_books` レコードを作成
6. 抽出したタグごとに `Tag.find_or_create_safely!` で取得・生成し、`user_book_tags` を作成（並列リクエストで同名タグが同時作成された場合は `RecordNotUnique` を検知して作成済みレコードを再検索する）
7. `purchase_links` があれば `user_book_purchase_links` レコードを作成

## レスポンス

### 成功

```json
// 201 Created
{
  "message": "登録が完了しました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `NOT_FOUND` | 404 | 楽天書籍APIに書籍が存在しない |
| `CONFLICT` | 409 | すでに同じ書籍を登録済み |
| `VALIDATION_ERROR` | 422 | バリデーション違反（ISBN不正・content超過・ハッシュタグ数超過・purchase_links違反。`field` に違反フィールド名を含む場合あり） |
| `EXTERNAL_API_ERROR` | 503 | 楽天書籍APIがエラー・タイムアウトを返した |

```json
// VALIDATION_ERROR レスポンス例（purchase_links 違反時）
{
  "code": "VALIDATION_ERROR",
  "field": "purchase_links"
}
```

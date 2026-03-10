# GET /v1/users/:username/skill_map

## 概要

指定したユーザーのスキルマップを取得する。
`status = completed` の本棚投稿に付いたタグの読了数を集計して返す。

## リクエスト

### 認証

不要

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:username` | string | 取得するユーザーの username |

## 処理詳細

1. `username` で User レコードを検索
2. そのユーザーの `status = completed` の `user_books` に紐付く `user_book_tags` を集計
3. タグ別の読了数を読了数の降順で返す

## レスポンス

### 成功

```json
// 200 OK
{
  "skill_map": [
    { "tag": "Go", "count": 12 },
    { "tag": "Architecture", "count": 8 },
    { "tag": "TypeScript", "count": 5 }
  ]
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `NOT_FOUND` | 404 | ユーザーが存在しない |

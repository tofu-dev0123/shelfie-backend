# POST /v1/me/tag_follows/:tag_name

## 概要

タグをフォローする。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:tag_name` | string | フォローするタグ名（例: `Go`）|

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. `tag_name` でタグを検索
3. `tag_follows` レコードを作成

## レスポンス

### 成功

```json
// 201 Created
{
  "message": "フォローしました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `NOT_FOUND` | 404 | タグが存在しない |
| `CONFLICT` | 409 | すでにフォロー済み |

# PUT /v1/me/links

## 概要

プロフィールリンクを全件置き換えで更新する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### ボディ

```json
{
  "links": [
    "https://github.com/komusan",
    "https://x.com/komusan"
  ]
}
```

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `links` | array | 必須 | 最大5件 |
| `links[]` | string | 必須 | URL形式 |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. ボディのバリデーション
3. ログインユーザーの `user_links` レコードを全削除
4. 送信された URL を新規作成
5. 更新後のリンク一覧を返す

## レスポンス

### 成功

```json
// 200 OK
{
  "links": [
    "https://github.com/komusan",
    "https://x.com/komusan"
  ]
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `VALIDATION_ERROR` | 422 | URL形式不正・5件超過 |

# POST /v1/auth/refresh

## 概要

HttpOnly Cookie のリフレッシュトークンを検証し、新しいアクセストークンを発行する。

## リクエスト

### 認証

`Cookie: refresh_token=<リフレッシュトークン>`

## 処理詳細

1. Cookie からリフレッシュトークンを取得
2. `refresh_tokens` テーブルでトークンの存在・有効期限を検証
3. 新しいアクセストークン（60分）を発行して返す

## レスポンス

### 成功

```json
// 200 OK
{
  "access_token": "eyJ..."
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | リフレッシュトークンが無効・期限切れ・DB に存在しない |

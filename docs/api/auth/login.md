# POST /v1/auth/login

## 概要

Clerk JWT を検証し、バックエンド独自のアクセストークンとリフレッシュトークンを発行する。

## リクエスト

### 認証

`Authorization: Bearer <Clerk JWT>`

## 処理詳細

1. `Authorization` ヘッダーから Clerk JWT を取得
2. `clerk-sdk-ruby` で Clerk JWT を検証し、`clerk_user_id` / `email` を取得
3. `clerk_user_id` で User レコードを検索
4. アクセストークン（60分）・リフレッシュトークン（30日）を発行
5. リフレッシュトークンを `refresh_tokens` テーブルに保存
6. アクセストークンをレスポンスボディ、リフレッシュトークンを HttpOnly Cookie で返す

## レスポンス

### 成功

```json
// 200 OK
{
  "access_token": "eyJ..."
}
```

```
Set-Cookie: refresh_token=eyJ...; HttpOnly; Secure; SameSite=Lax; Domain=shelfie.com
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | Clerk JWT が無効・期限切れ |
| `NOT_FOUND` | 404 | User レコードが存在しない（サインアップ未完了） |

# POST /v1/users

## 概要

Clerk JWT を検証し、nickname・username を受け取って User レコードを作成する。作成後はそのままアクセストークン・リフレッシュトークンを発行してログイン状態にする。

## リクエスト

### 認証

`Authorization: Bearer <Clerk JWT>`

### ボディ

```json
{
  "nickname": "コムさん",
  "username": "komusan"
}
```

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `nickname` | string | 必須 | 最小1文字・最大50文字 |
| `username` | string | 必須 | 英数字・アンダースコアのみ、最小4文字・最大40文字、保存時に小文字へ正規化 |

## 処理詳細

1. `Authorization` ヘッダーから Clerk JWT を検証し、`clerk_user_id` / `email` を取得
2. `clerk_user_id` で既存 User レコードの存在チェック（重複登録防止）
3. `username` の重複チェック
4. User レコードを作成（`avatar_key` は null、デフォルト画像はフロントで制御）
5. アクセストークン（60分）・リフレッシュトークン（30日）を発行
6. リフレッシュトークンを `refresh_tokens` テーブルに保存
7. アクセストークンをレスポンスボディ、リフレッシュトークンを HttpOnly Cookie で返す

## レスポンス

### 成功

```json
// 201 Created
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
| `ACCOUNT_ALREADY_EXISTS` | 409 | `clerk_user_id` が重複（登録済みユーザー） |
| `USERNAME_TAKEN` | 409 | `username` が重複 |
| `UNPROCESSABLE_ENTITY` | 422 | nickname・username のバリデーション違反 |

`UNPROCESSABLE_ENTITY` 時のレスポンス例：

```json
{
  "error": {
    "code": "UNPROCESSABLE_ENTITY",
    "message": "入力内容に誤りがあります",
    "details": [
      { "field": "username", "message": "ユーザー名は4文字以上で入力してください" },
      { "field": "nickname", "message": "ニックネームは必須です" }
    ]
  }
}
```

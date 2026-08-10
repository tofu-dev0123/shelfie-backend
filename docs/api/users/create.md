# POST /v1/users

## 概要

コールバックが発行した `signup_token` を検証し、nickname・username を受け取って User・UserIdentity レコードを作成する。作成後はそのままアクセストークン・リフレッシュトークンを発行してログイン状態にする。

## リクエスト

### 認証

`Cookie: signup_token=<JWT>`（`purpose: "signup"`、10分）

`provider` / `uid` / `email` は `signup_token` から取り出す。フロントから送らせない（詐称を防ぐため）。

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

1. `signup_token` Cookie を `purpose` 込みで検証し、`provider` / `uid` / `email` / `name` を取得
2. `(provider, provider_uid)` で `user_identities` の存在チェック（重複登録防止）
3. `username` の重複チェック
4. 以下を**1トランザクション**で作成する
   - User レコード
   - UserIdentity レコード
   - リフレッシュトークン（30日）と `refresh_tokens` レコード
5. アクセストークン（60分）を発行
6. アクセストークンをレスポンスボディ、リフレッシュトークンを HttpOnly Cookie で返し、`signup_token` Cookie を破棄する

3つが揃って初めてログインできる状態になるため、途中で落ちたときに「連携先が無い」「セッションが張れない」ユーザーが残らないよう1トランザクションにまとめている。

## レスポンス

### 成功

```json
// 201 Created
{
  "access_token": "eyJ..."
}
```

```
Set-Cookie: refresh_token=eyJ...; Path=/; HttpOnly; Secure; SameSite=Lax; Domain=shelfie.com
Set-Cookie: signup_token=; Path=/; Max-Age=0
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | `signup_token` Cookie が無効・期限切れ・`purpose` 不一致 |
| `ACCOUNT_ALREADY_EXISTS` | 409 | `(provider, provider_uid)` が既に `user_identities` に存在 |
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

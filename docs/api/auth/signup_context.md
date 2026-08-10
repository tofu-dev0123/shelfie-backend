# GET /v1/auth/signup_context

## 概要

サインアップ画面の初期表示に必要な情報を返す。

フロントは IdP のプロフィールを一切見られないため、①nickname のプリフィル元を取得できない ②`signup_token` の期限切れに送信ボタンを押すまで気づけない、の2つが起きる。画面表示時にこのエンドポイントを叩き、401 なら入力前に `/login` へ戻す。

## リクエスト

### 認証

`Cookie: signup_token=<JWT>`（`purpose: "signup"`、10分）

クエリパラメータ・ボディはない。

## 処理詳細

1. `signup_token` Cookie を `purpose` 込みで検証する
2. `email` / `name` クレームを取り出して返す

## レスポンス

### 成功

```json
// 200 OK
{
  "email": "user@example.com",
  "nickname_suggestion": "コムサン"
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `email` | string | IdP が返したメール（`signup_token` の `email` クレーム） |
| `nickname_suggestion` | string | `signup_token` の `name` クレーム。null のときは空文字 |

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | Cookie なし / 署名不正 / 期限切れ（10分） / `purpose` が `signup` でない |

```json
{
  "error": { "code": "UNAUTHORIZED", "message": "認証に失敗しました" }
}
```

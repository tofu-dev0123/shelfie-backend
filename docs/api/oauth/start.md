# GET /auth/:provider

## 概要

OAuth の認可リクエストを開始する。state と PKCE の `code_verifier` を発行して署名付き Cookie に格納し、IdP の認可エンドポイントへリダイレクトする。

`/v1` の外に置いている。JSON API ではなくブラウザのトップレベル遷移で叩かれるエンドポイントであり、レスポンスは常に 302 リダイレクトになるため。

## リクエスト

### 認証

不要（未ログインの入口）。

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:provider` | string | `google` / `github` のみ。それ以外はルーティング制約で 404 |

### クエリパラメータ

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `intent` | string | 任意 | 既定 `auth`。v1 で使うのは `auth` のみ（`link` は v2 のスコープ外） |

## 処理詳細

1. `state`（32バイト）と `code_verifier`（64バイト）を生成する
2. `{purpose, provider, intent, state, code_verifier}` を JWT（10分）に署名し、`oauth_state` Cookie に格納する
3. `code_challenge` を `BASE64URL(SHA256(code_verifier))`（パディングなし）で算出する
4. プロバイダの認可エンドポイントの URL を組み立てて 302 する

## レスポンス

### 成功

```
302 Found
Location: https://accounts.google.com/o/oauth2/v2/auth?client_id=...&redirect_uri=https%3A%2F%2Fapi.shelfie...%2Fauth%2Fgoogle%2Fcallback&response_type=code&scope=openid+email+profile&state=...&code_challenge=...&code_challenge_method=S256
Set-Cookie: oauth_state=eyJ...; Max-Age=600; Path=/auth; HttpOnly; Secure; SameSite=Lax
```

ボディは返さない。

`oauth_state` は `Domain` を指定せずホスト限定にし、`Path=/auth` で送信範囲を絞る。
`SameSite` は `Lax`。`Strict` にすると IdP からの復帰で Cookie が送られず、すべてのログインが state 不一致で落ちる。

### エラー

| code | ステータス | 場面 |
|---|---|---|
| （ボディなし） | 404 | `:provider` が `google` / `github` 以外（ルーティング制約） |

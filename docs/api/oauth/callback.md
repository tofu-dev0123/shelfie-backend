# GET /auth/:provider/callback

## 概要

IdP からの認可レスポンスを受け取り、既存ユーザーならログイン、未登録ならサインアップ導線へ振り分ける。

`/v1` の外に置いている。ブラウザのトップレベル遷移で叩かれるため、**成否によらず必ず 302 リダイレクトで返す**。JSON を返すと生の JSON がページとして表示されてしまうので、このエンドポイントだけは `ErrorHandler` を通さない。

## リクエスト

### 認証

不要。`oauth_state` Cookie と `state` クエリの照合で担保する。

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:provider` | string | `google` / `github` |

### クエリパラメータ

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `code` | string | 任意 | 認可コード（成功時） |
| `state` | string | 任意 | CSRF 対策の照合値 |
| `error` | string | 任意 | 同意画面でキャンセルされた場合に IdP が付ける |

### Cookie

| 名前 | 必須 | 内容 |
|---|---|---|
| `oauth_state` | 必須 | `{purpose, provider, intent, state, code_verifier}`（10分） |

## 処理詳細

**この順序を変えないこと。**

1. `oauth_state` Cookie を**冒頭で削除**する（成否によらず。認可コードのリプレイ防止）
2. `error` があれば `cancelled` で離脱する
3. `state` を `ActiveSupport::SecurityUtils.secure_compare` で固定時間比較する
4. Cookie の `provider` と URL の `provider` が一致することを確認する
5. 認可コードを交換して `Oauth::Identity`（`provider` / `uid` / `email` / `name`）を得る
6. `user_identities` を `(provider, provider_uid)` で検索して分岐する
   - ヒット → リフレッシュトークンを発行して `refresh_tokens` に保存し、ログインとして返す
   - ヒットしない → 同一メールの既存ユーザーがいれば `email_already_registered` で離脱、いなければ `signup_token` を発行する

同一メールの既存ユーザーがいても**自動では紐付けない**。IdP のメールを根拠に既存アカウントへ接続できてしまうため、複数プロバイダの連携は別途 UI で行う。

## レスポンス

### 成功（既存ユーザー = ログイン）

```
302 Found
Location: {FRONTEND_URL}/
Set-Cookie: refresh_token=eyJ...; Path=/; HttpOnly; Secure; SameSite=Lax; Domain={COOKIE_DOMAIN}
```

### 成功（新規ユーザー = サインアップ）

```
302 Found
Location: {FRONTEND_URL}/signup
Set-Cookie: signup_token=eyJ...; Max-Age=600; Path=/; HttpOnly; Secure; SameSite=Lax; Domain={COOKIE_DOMAIN}
```

### エラー

すべて 302 で `{FRONTEND_URL}/login?error=<code>` に返す。JSON は返さない。

| `error=` | 発生場面 |
|---|---|
| `cancelled` | 同意画面でキャンセル（IdP が `error` を付けて戻る） |
| `invalid_state` | `oauth_state` Cookie が無い / 壊れている / 期限切れ（10分） |
| `invalid_state` | `state` が Cookie の値と一致しない |
| `invalid_state` | Cookie の `provider` と URL の `provider` が食い違う |
| `invalid_state` | `code` が空 |
| `provider_error` | トークン交換が失敗（IdP が 4xx/5xx、または 200 で `{error:...}`） |
| `provider_error` | `id_token` の `iss` / `aud` / `exp` / `email_verified` が不正（Google） |
| `email_unavailable` | verified な primary メールが取得できない（GitHub 特有） |
| `email_already_registered` | 同一メールの既存ユーザーがいる（別プロバイダで登録済み） |
| `provider_error` | 上記以外の想定外例外（フォールバック） |

リダイレクト先は `ENV.fetch("FRONTEND_URL")` 固定で、`params` 由来の値を混ぜない（オープンリダイレクト防止）。

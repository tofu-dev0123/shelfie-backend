# 認証フロー

## 認証が必要な操作

| 操作 | ログイン |
|---|---|
| 本棚・書籍・ユーザーの閲覧 | 不要 |
| 投稿・編集・削除 | 必須 |

> 例外: `GET /v1/books/search` と `GET /v1/books/:isbn` は楽天書籍APIのリクエスト制限対策のため認証必須。

---

## 認証方式

**Rails が OAuth を所有する。** ログインは Google / GitHub の
**認可コードフロー + PKCE(S256)** で行い、認可コードの交換もバックエンドが自分で行う。
フロントエンドは認証の当事者にならず、API を叩くだけである。

採用理由と却下した案（マネージド認証サービス / Auth.js / OmniAuth）は
[ADR 009: 認証方式](../decisions/009-authentication.md) に記録している。

### 入口は `/v1` の外にある

| エンドポイント | 役割 |
|---|---|
| `GET /auth/:provider` | 認可リクエストの開始。IdP の認可 URL へ 302 |
| `GET /auth/:provider/callback` | IdP からの復帰。成否によらず 302 で返す |

この2つは**ブラウザのトップレベル遷移**で叩かれるため JSON API ではない。
`V1::BaseController` を継承せず `ErrorHandler` も通さない
（詳細は [docs/api/oauth/callback.md](../api/oauth/callback.md)）。

---

## 4種のトークン

すべて `jwt` gem の JWT（HS256）で、**種別は `purpose` クレームにしか書かれていない。**

### 署名鍵

**署名鍵は環境変数 `JWT_SECRET_KEY`**（`TokenIssuer::SECRET_KEY`）。
`Oauth::State` もこの定数を参照するため、鍵の定義は1箇所しかない。

Rails の `secret_key_base` とは**分けている**。フレームワークが署名 Cookie・`signed_id` 等に
使う汎用の鍵と共有すると、認証トークンだけをローテーションできず、漏洩時の影響範囲も広がるため。

未設定（および空文字）のときは production の**起動時**に `KeyError` で落ちる
（`secret_key_base` へ静かにフォールバックしない）。開発とテストのみ既定値を持つ。

鍵を `app/constants/` ではなく `TokenIssuer` に置いているのは、`lib/` から `app/` への
依存を作らないため。有効期限や `purpose` と同じく、**発行するクラスが持つ**。

| トークン | `purpose` | 有効期限 | 置き場 | 中身 |
|---|---|---|---|---|
| `oauth_state` | `oauth_state` | 10分 | HttpOnly Cookie（`Path=/auth`・ホスト限定） | `provider` / `intent` / `state` / `code_verifier` |
| `signup_token` | `signup` | 10分 | HttpOnly Cookie（`Path=/`） | `provider` / `uid` / `email` / `name` |
| `refresh_token` | `refresh` | 30日 | HttpOnly Cookie（`Path=/`）+ `refresh_tokens` テーブル | `user_id` |
| `access_token` | `access` | 60分 | **フロントのメモリ（JS変数）** | `user_id` |

### `purpose` クレームで種別を検証する理由

4種すべてが**同じ鍵で署名される**ため、`purpose` が無いと相互に通用してしまう。
とくに30日有効な `refresh_token` を `Authorization: Bearer` に入れると
アクセストークンとして通ってしまう。

`TokenIssuer.decode` は `purpose` を**必須キーワード引数**で受け取り、
一致しない場合は `nil` を返す。呼び出し側が種別の検証を省略できない形にしている。

```ruby
# lib/token_issuer.rb
TokenIssuer.decode(token, purpose: TokenIssuer::PURPOSE_ACCESS)
```

逆方向（`access_token` をリフレッシュに使う）は `Auth::RefreshService` が
`refresh_tokens` テーブルとの照合で完結しており、発行時に保存していない
`access_token` はその時点で弾かれる。

### トークン形式の定数の置き場

有効期限と `purpose` は「そのトークンが何であるか」の定義なので、
発行するクラス（`lib/token_issuer.rb` / `lib/oauth/state.rb`）が持つ。
運用の判断である `REFRESH_ROTATION_THRESHOLD` は `app/constants/auth_constants.rb`
に置く。線引きの根拠は
[実装ガイドライン](../development/implementation-guidelines.md#定数の置き場) を参照。

### Cookie はすべて `SameSite=Lax`

`Strict` にすると IdP からの復帰（クロスサイトのトップレベル GET）で Cookie が
送られず、**すべてのログインが state 不一致で落ちる。**

`oauth_state` だけは `domain` を指定せずホスト限定にし、`Path=/auth` で
送信範囲も絞る。認可リクエストとコールバックの2アクションでしか使わないため。

### アクセストークンをメモリに置く理由

localStorage は XSS でスクリプトから読み取られる。メモリ（JS変数）に置けばそのリスクを排除できる。
ページリロード時は `refresh_token` Cookie から再取得する。

**`access_token` は一度も URL に載らない。** ブラウザ履歴・Referer・サーバーログのどこにも残らない。

---

## 認証フロー（ログイン）

```
 ブラウザ            Next.js           Rails API          Google/GitHub
    │                  │                  │                    │
 ①  │ GET /login       │                  │                    │
    ├─────────────────>│                  │                    │
    │  <a href="{API}/auth/google">        │                    │
    │<─────────────────┤                  │                    │
    │                  │                  │                    │
 ②  │ リンククリック = トップレベル遷移      │                    │
    │ GET /auth/google │                  │                    │
    ├─────────────────────────────────────>│                    │
    │                  │      ③ state / code_verifier を生成    │
    │                  │         → oauth_state Cookie にセット  │
    │                  │           (10分/HttpOnly/Secure/Lax)   │
 ④  │ 302 → IdP の認可URL（state + code_challenge 付き）        │
    │<─────────────────────────────────────┤                    │
 ⑤  │ GET 認可画面                                              │
    ├──────────────────────────────────────────────────────────>│
 ⑥  │ ユーザーが同意                                            │
    │<──────────────────────────────────────────────────────────┤
 ⑦  │ 302 → /auth/google/callback?code=..&state=..              │
    │   （クロスサイトのトップレベル GET → SameSite=Lax の Cookie が同送）
    ├─────────────────────────────────────>│                    │
    │                  │      ⑧ oauth_state Cookie を即削除     │
    │                  │         state を固定時間比較で照合      │
 ⑨  │                  │                  │ POST トークン交換   │
    │                  │                  │ client_secret + code + code_verifier
    │                  │                  ├───────────────────>│
    │                  │                  │ Google: id_token / GitHub: access_token
    │                  │                  │<───────────────────┤
    │                  │      ⑩ 本人情報を取り出す               │
    │                  │         ⇒ Oauth::Identity{provider,uid,email,name}
    │                  │      ⑪ user_identities を (provider, provider_uid) で検索 → ヒット
    │                  │      ⑫ refresh_token を発行し DB に保存 │
 ⑬  │ 302 → {FRONTEND_URL}/ + Set-Cookie: refresh_token         │
    │<─────────────────────────────────────┤                    │
 ⑭  │ GET / → Next.js                      │                    │
 ⑮  │ POST /v1/auth/refresh（Cookie）      │                    │
    ├─────────────────────────────────────>│                    │
    │ { "access_token": "eyJ..." }         │                    │
    │<─────────────────────────────────────┤                    │
 ⑯  │ access_token をメモリに保持 → ログイン完了                 │
```

`user_identities` に該当が無い場合はサインアップ導線へ分岐する。
詳細は [サインアップフロー](./signup.md) を参照。

### state と PKCE をサーバー側に持たない理由

`state` / `code_verifier` は**10分だけ生きる署名付き Cookie**（`oauth_state`）に載せる。
サーバー側にセッションを持たないため `config.api_only = true` を崩さずに済む。

改竄・期限切れ・`purpose` 違いはすべて `nil` に潰し、呼び出し側は区別せず
`invalid_state` として扱う（`lib/oauth/state.rb`）。

### PKCE を使う理由

認可コードが漏れても `code_verifier` を知らなければトークンに交換できない。
`code_challenge_method` は `S256` のみ使う（`plain` は使わない。GitHub も `S256` に対応している）。

---

## プロバイダ差の吸収

**プロバイダごとの違いは `lib/oauth/providers/` に閉じる。**
ここより上（`app/services/oauth/**`・`OauthController`）に `google` / `github` という
名前が出てきたら設計が崩れているサイン。

| 工程 | Google | GitHub |
|---|---|---|
| 認可URL組立 | 共通実装（URL と `scope` の定数だけ違う） | 同左 |
| state / PKCE(S256) | 共通実装 | 同左 |
| コード交換 | 共通実装（URL の定数だけ違う） | 同左 |
| **本人情報の取り出し** | **`id_token` のクレーム** | **`GET /user` + `GET /user/emails`** |
| 以降（ユーザー検索〜Cookie） | 共通実装 | 同左 |

3つ目のプロバイダを足すときに触るのは**クラス1個とレジストリ1行だけ**。

### Google: JWKS 検証が不要な理由

`id_token` を token endpoint から **TLS 越しに直接受領している**ため、
OIDC Core 3.1.3.7 により署名検証は TLS のサーバー検証で代替できる。

ただし以下4つは必ず検証する。とくに `aud` を落とすと
**他アプリ向けに発行された正規のトークンでなりすませる**（署名は本物なので気づけない）。

| クレーム | 検証内容 |
|---|---|
| `iss` | `accounts.google.com` または `https://accounts.google.com` |
| `aud` | 自分の `client_id` と一致するか |
| `exp` | 期限切れでないか |
| `email_verified` | true か |

### GitHub: メールが取れないことがある

GitHub はメール非公開設定が可能なため `GET /user` ではメールが取れない。
`GET /user/emails` から `primary` かつ `verified` のものを選び、
無ければ `email_unavailable` として失敗させる。

`uid` は整数で返るため文字列化する。`name` は null になりうるため `login` で代替する。

---

## コールバックのエラー分岐（全経路）

**すべての経路で `oauth_state` Cookie は最初に削除される。**
残すと同じ認可コードを再送されうる。

```
GET /auth/:provider/callback
    │
    ├─ params[:error] あり（同意画面でキャンセル）
    │     └─> /login?error=cancelled
    ├─ oauth_state Cookie が無い / 壊れている / 期限切れ(10分)
    │     └─> /login?error=invalid_state
    ├─ state が Cookie の値と一致しない
    │     └─> /login?error=invalid_state
    ├─ Cookie の provider と URL の provider が食い違う
    │     └─> /login?error=invalid_state
    ├─ トークン交換が失敗（IdP が 4xx/5xx、または 200 で {error:...}）
    │     └─> /login?error=provider_error
    ├─ id_token の iss / aud / exp / email_verified が不正（Google）
    │     └─> /login?error=provider_error
    ├─ verified な primary メールが取得できない（GitHub 特有）
    │     └─> /login?error=email_unavailable
    ├─ 同一メールの既存ユーザーがいる（別プロバイダで登録済み）
    │     └─> /login?error=email_already_registered
    ├─ 既存ユーザー ─> refresh_token 発行 ─> /       （refresh_token Cookie）
    └─ 新規ユーザー ─> signup_token 発行 ─> /signup （signup_token Cookie）
```

リダイレクト先は環境変数（`FRONTEND_URL`）で固定する。
**`params` 由来の値を混ぜるとオープンリダイレクトになる。**

---

## 通常リクエストのフロー

```
Next.js                              Rails API
  │                                      │
  │  APIリクエスト（Authorization: Bearer <access_token>）
  │─────────────────────────────────────>│
  │                                      │ purpose=access として検証
  │        レスポンス                    │
  │<─────────────────────────────────────│
```

`authenticate_user!` は `V1::BaseController` に置き、`v1/me/` 配下は
`V1::Me::BaseController` の `before_action` で全アクションに適用する。

---

## トークン再発行フロー（サイレントリフレッシュ）

アクセストークンが期限切れになった場合、ユーザーに意識させることなく自動で再発行する。

```
Next.js                              Rails API
  │                                      │
  │  APIリクエスト（期限切れのアクセストークン）
  │─────────────────────────────────────>│
  │  401 Unauthorized                    │
  │<─────────────────────────────────────│
  │                                      │
  │  POST /v1/auth/refresh（HttpOnly Cookie の refresh_token）
  │─────────────────────────────────────>│
  │                                      │ purpose=refresh として検証
  │                                      │ refresh_tokens テーブルで存在・期限を確認
  │  新しいアクセストークン               │
  │<─────────────────────────────────────│
  │                                      │
  │  元のAPIリクエストをリトライ          │
  │─────────────────────────────────────>│
```

残り有効期限が `AuthConstants::REFRESH_ROTATION_THRESHOLD`（15日）以下になった場合は
リフレッシュトークンも再発行する（スライディングウィンドウ方式）。

### リフレッシュトークンが期限切れの場合

401 を返し、フロントは `/login` へ戻す。ユーザーは `GET /auth/:provider` から再ログインする。

---

## ログアウトフロー

```
Next.js                              Rails API
  │                                      │
  │  DELETE /v1/auth/logout              │
  │─────────────────────────────────────>│
  │                                      │ refresh_tokens のレコードを削除
  │                                      │ refresh_token Cookie を削除
  │  200 OK                              │
  │<─────────────────────────────────────│
  │                                      │
  │  アクセストークンをメモリから削除     │
```

---

## refresh_tokens テーブル

リフレッシュトークンを DB で管理することで、デバイスごとの個別ログアウトと
強制ログアウトを実現する。JWT 単体では無効化できないため。

| 操作 | DB の操作 |
|---|---|
| ログイン | レコードを作成 |
| サインアップ | レコードを作成（ユーザー作成と同一トランザクション） |
| ログアウト（1デバイス） | そのデバイスのレコードを削除 |
| 全デバイスログアウト | `user_id` に紐づく全レコードを削除 |

カラム定義 → [refresh_tokens テーブル](./tables/refresh_tokens.md)

---

## 使用 gem

| gem | 用途 |
|---|---|
| `jwt` | 4種すべてのトークンの発行・検証 |

**OAuth 移行にあたり gem の追加はゼロである。** 理由は
[ADR 009](../decisions/009-authentication.md) の「なぜ OmniAuth ではなく自前プロバイダ層か」を参照。

---

## 関連ドキュメント

- [ADR 009: 認証方式](../decisions/009-authentication.md)
- [サインアップフロー](./signup.md)
- [技術スタック選定理由](./tech-stack.md)
- [データモデル](./data-model.md)
- [user_identities テーブル](./tables/user_identities.md)
- [GET /auth/:provider](../api/oauth/start.md) / [GET /auth/:provider/callback](../api/oauth/callback.md)

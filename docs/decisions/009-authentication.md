# 009: 認証方式（Rails が OAuth を所有する）

> 番号 004 は欠番。

## 決定日

2026-08-08（issue #134 で方針確定）

## ステータス

決定済み

## 背景

当初は Clerk（Google OAuth）で本人確認を行い、Rails は Clerk JWT を一度だけ検証して
独自の JWT を発行する構成だった。**Clerk が担っていたのは「入口の本人確認」1点だけ**で、
`TokenIssuer` / `refresh_tokens` / 全 API の認証ロジックは Clerk に依存していなかった。

その入口を差し替えるにあたり、3段階の判断が必要だった。

1. Clerk を残すか、やめるか
2. やめるなら、認証を**どちらのサーバーが所有するか**（Next.js か Rails か）
3. Rails が所有するなら、OmniAuth を使うか自前で書くか

---

## 決定内容

**Rails が OAuth を所有する。** 認可コードフロー + PKCE(S256) を自前のプロバイダ層で実装し、
Google と GitHub の両方に対応する。gem の追加はゼロ。

フローの詳細 → [docs/architecture/auth.md](../architecture/auth.md)

---

## なぜ Clerk をやめたか

当初は「ユーザーが自分1人の間は移行の便益がゼロなので Clerk のまま出す」と判断していたが、
**撤回した。** 便益の見積もりが間違っていたのではなく、**残す側にもコストがあることを
見落としていた**のが理由である。

| | 内容 |
|---|---|
| **ブランディングが目的を壊す** | 無料プランではクライアントの認証フローに Clerk のブランディングが出る。アプリがチープに見える。これは「個人サイトの Books ページの飛び先を本物のサービスにする」という**プロダクトの目的そのものを壊す** |
| **残す側にも作業が発生する** | Clerk の本番インスタンス構築（独自ドメインの DNS 設定など）が必要。「何もしなくてよい」わけではない |

2つを併せると **「作業して、目的は達成されない」** ことになり、
Clerk を残す選択肢の優位性が消えた。移行の便益がゼロでも、
残す側のコストが正で目的達成度が負なら、残す理由はない。

---

## なぜ Auth.js ではなく Rails が OAuth を所有するか

争点は「フロント vs バックエンド」ではなく、**どちらのサーバーが認証を所有するか**だった。

Auth.js は Next.js の**サーバー側**で動き、`client_secret` を保持し、認可コード交換もそこで行う。
この案（以下、案A）を採ると、フロントは「API を叩くだけ」ではなく
**サーバーサイドの認証ロジックと `client_secret` を持つ当事者**になる。

| | 案A（Auth.js が所有） | 案C（Rails が所有・採用） |
|---|---|---|
| `client_secret` の保管先 | Next.js（1箇所増える） | **Rails のみ** |
| Rails が受け取るもの | `id_token`（信頼できない経路） | token endpoint から**直接 TLS で**受領 |
| **JWKS 検証** | **必須** | **不要** |
| セッションの所有者 | Auth.js と Rails の二重 | **Rails のみ** |

### JWKS 検証という攻撃面を持たない

案Aだと「フロントから来た文字列を疑う」処理が認証の本体になる。
このとき **`aud` の検証を落とすと、他人のアプリ向けに発行された正規のトークンで
なりすませる**（署名は本物なので気づけない）。

案Cはこのクラスの脆弱性が**構造的に存在しない**。
Rails が自分でコード交換するため、手に入るトークンは定義上このアプリのものである。

### クロスドメイン Cookie は最初から問題にならなかった

案Cの最大の障壁と見ていたのはリフレッシュ Cookie の扱いだったが、
現行コードに前提が既に入っていた。

- `app/controllers/concerns/refresh_token_cookie.rb` … `same_site: :lax`
- `config/environments/production.rb` … `COOKIE_DOMAIN`

`SameSite=Lax` の Cookie はクロスサイトの `fetch` では送信されない。つまり
**現行のリフレッシュ機構は「Next.js と Rails が同一の親ドメインに載る」ことを既に前提にしている。**
同一親ドメインなら、懸念していたクロスドメイン Cookie の問題は発生しない。

### GitHub は OIDC ではないため案Aが構造的に成立しない

プロダクト方針として **Google / GitHub 両方**のログインを実現すると決まった時点で、
案Aは選択不可能になった。

**GitHub は OIDC ではないため `id_token` を返さない。**
案Aの橋は Google の `id_token` 1本で成り立っていたので、GitHub には架からない。
迂回策は2つだけで、どちらも案Aを選んだ理由を壊す。

| 迂回策 | 壊れるもの |
|---|---|
| `access_token` を Rails に送って `GET /user` を叩く | GitHub の access_token は**どの OAuth App 向けに発行されたか判別できない**。他アプリのトークンを投げ込めば**なりすましが成立する**（案Cを選んだ理由と同じクラスの脆弱性） |
| `POST /applications/{client_id}/token` で照会する | **Rails にも GitHub の `client_secret` が必要**になり、Next.js と合わせて**同じ秘密が2箇所に複製される** |

案Cなら照会そのものが不要である。

---

## なぜ OmniAuth ではなく自前プロバイダ層か

Rails が OAuth を所有すると決めたあと、OmniAuth（案C-1）と自前実装（案C-2）を比較した。
**この構成では OmniAuth の利点が発揮されない。**

### `api_only` を崩さない

**OmniAuth の OAuth2 ストラテジは `state` / `code_verifier` の置き場に Rails の `session` を使う。**
`config.api_only = true` は session middleware を積まないため、
**cookies + session middleware を戻す必要がある。**
これは「セッションの所有者を1つにする」という案Cの判断軸に自分で反する。

自前にすると `state` / `code_verifier` は**10分だけ生きる署名付き Cookie**（`oauth_state`）に
載せられ、サーバー側に状態を持たない。`api_only` を崩さずに済む。

### CSRF gem とリンク遷移が両立しない

**`omniauth-rails_csrf_protection` と「リンク遷移」は両立しない。**
OmniAuth 2.0 の既定は `allowed_request_methods = [:post]` で、加えて同 gem は
Rails の authenticity token を要求する。

`api_only` + Next.js 分離の構成で CSRF トークンを取得するには、
セッション Cookie とトークン発行エンドポイントが要る。
これは**「フロントは API を叩くのみ」という判断軸そのものを壊す。**

CVE 対策として入っている gem を無効化して回避する、という判断もしたくない。

### 差分は約100行

`OauthController` / `CallbackService` / `signup_token` 一式 / `user_identities` は
**OmniAuth を使っても残る**ため、実質差分は約100行の純増にとどまる。

その100行と引き換えに得るもの。

- gem ゼロ本（`config.api_only = true` を維持）
- CVE 対策を自分で無効化する判断の回避
- プロバイダ差の吸収層が**自分のドメインの型**（`Oauth::Identity`）になる

### プロバイダ差が2メソッドに閉じる

自前にすることで、プロバイダごとの違いが `build_identity` の実装だけになった。

| 工程 | 差 |
|---|---|
| 認可URL組立 / state・PKCE / コード交換 | 定数（URL・scope）のみ |
| **本人情報の取り出し** | **Google は `id_token`、GitHub は `GET /user` + `GET /user/emails`** |
| ユーザー検索〜Cookie 発行 | 差なし |

3つ目のプロバイダを足すときに触るのは**クラス1個とレジストリ1行だけ**である。

---

## 結果

| | 移行前 | 移行後 |
|---|---|---|
| 入口の本人確認 | Clerk（フロント主導） | Rails（`GET /auth/:provider`） |
| プロバイダ | Google | Google / GitHub |
| gem | `clerk-sdk-ruby` + `jwt` | `jwt` のみ |
| JWT の種別 | access / refresh | access / refresh / signup / oauth_state（`purpose` で検証） |
| identity の持ち方 | `users.clerk_user_id` | `user_identities`（1ユーザー = N プロバイダを表現可能） |
| セッションの所有者 | Rails | Rails |

`TokenIssuer` / `refresh_tokens` / 全 API の認証ロジックは**無変更**で移行できた。

## 副次的な決定

- **同一メールで別プロバイダが来たら拒否して案内する（P1）。**
  決め手は可逆性 → [docs/architecture/signup.md](../architecture/signup.md)
- **`purpose` クレームで4種のトークンを区別する。**
  同じ鍵で署名されるため、無いと相互に通用する → [docs/architecture/auth.md](../architecture/auth.md)
- **`/v1` 外のコントローラ（`OauthController`）を例外として認める** →
  [001: コントローラーのディレクトリ構成](./001-controller-structure.md)

## 関連ドキュメント

- [認証フロー](../architecture/auth.md)
- [サインアップフロー](../architecture/signup.md)
- [user_identities テーブル定義](../architecture/tables/user_identities.md)
- [技術スタック選定理由](../architecture/tech-stack.md)

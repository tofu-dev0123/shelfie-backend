# ユーザー登録（サインアップ）フロー

## 概要

OAuth のコールバックで本人確認が済んだあと、`user_identities` に該当が無ければ
サインアップ導線へ分岐する。**`signup_token`（10分）が本人確認済みの情報を
サインアップ完了まで運ぶ。**

フロントエンドは IdP のプロフィールを一切見られない（それが
[ADR 009](../decisions/009-authentication.md) で Rails に OAuth を所有させた利点である）。
その代わりに `GET /v1/auth/signup_context` が nickname のプリフィル元を返す。

認証の全体像 → [認証フロー](./auth.md)

---

## 登録フロー

①〜⑩は[ログイン](./auth.md#認証フローログイン)と完全に同一。⑪の検索結果で分岐する。

```
    │      ⑪ user_identities を (provider, provider_uid) で検索 → 該当なし
    │      ⑫ users.email の重複を確認
    │         ├─ 重複あり → /login?error=email_already_registered
    │         └─ 重複なし → 続行
    │      ⑬ signup_token を発行（10分・HttpOnly Cookie）
    │         { purpose:"signup", provider, uid, email, name }
 ⑭ │ 302 → {FRONTEND_URL}/signup + Set-Cookie: signup_token
 ⑮ │ GET /signup（Next.js）
 ⑯ │ GET /v1/auth/signup_context（Cookie）
    │   → { email, nickname_suggestion }
    │   → 401 なら「セッション切れ」として /login へ戻す
 ⑰ │ GET /v1/users/username/check?value=xxx（デバウンス）
 ⑱ │ POST /v1/users { nickname, username }（Cookie）
    │      ⑲ signup_token を purpose 込みで検証
    │         ┌─ 1トランザクション ────────┐
    │         │ users を INSERT            │
    │         │ user_identities を INSERT  │
    │         │ refresh_tokens を INSERT   │
    │         └────────────────────────────┘
 ⑳ │ 201 { access_token } + refresh_token Cookie
```

3つが揃って初めてログインできる状態になるため、1トランザクションで作成する。
途中で落ちると「連携先が無い」「セッションが張れない」ユーザーが残る。

### signup_token をサーバー側に保存しない理由

離脱したサインアップの残骸を DB に溜めないため。10分で自然に消える。

フロントは `signup_token` に一切触れない（HttpOnly Cookie として自動送信されるだけ）。
**`provider` / `uid` / `email` をフロントから送らせない**ことで詐称を防いでいる。

---

## `GET /v1/auth/signup_context` が必要な理由

フロントが IdP のプロフィールを見られないことの副作用が2つある。

| 問題 | この API で解決 |
|---|---|
| nickname のプリフィル元（IdP の表示名）が取得できない | `nickname_suggestion` を返す |
| `signup_token`（10分）の期限切れに、送信ボタンを押すまで気づけない | 画面表示時に 401 を返し、入力前に `/login` へ戻せる |

`name` クレームは IdP 側で未設定なら null になるため、`nickname_suggestion` は
空文字へ倒して返す（フロントの入力欄にそのまま差し込めるようにするため）。

仕様 → [GET /v1/auth/signup_context](../api/auth/signup_context.md)

---

## 途中離脱後の再訪問フロー

`signup_token` は10分で切れる。切れたあとは Cookie が失効しているだけなので、
`GET /auth/:provider` からやり直すことになる。

```
ページ読み込み（/signup）
    ↓
GET /v1/auth/signup_context（signup_token Cookie）
    ↓
200 OK        ─→ そのままサインアップを再開（10分以内）
401 Unauthorized ─→ /login へ（IdP からやり直す）
```

### 状態と画面遷移まとめ

| refresh_token Cookie | signup_token Cookie | 遷移先 |
|---|---|---|
| なし | なし | ログイン画面 |
| なし | あり（10分以内） | サインアップ画面 |
| あり | - | ホーム画面 |

---

## 同一メールで別プロバイダが来たときのポリシー：**P1（拒否して案内）**

`user_identities` に該当が無く、かつ `users.email` に同じメールの既存ユーザーがいる場合、
**自動では紐付けず `/login?error=email_already_registered` へ返す。**
フロントは「このメールは既に登録済みです。登録済みのプロバイダでログインしてください」と案内する。

| | 動作 | 評価 |
|---|---|---|
| **P1（採用）** | 拒否して案内。連携は後から設定画面で明示的に行う | 安全。**後から P2 へ緩められる** |
| P2 | `verified` 条件付きで自動紐付け | UX は最良だが、**弱い方のプロバイダのメール検証強度がアカウント全体の強度になる**。統合後の**分離は不可能** |
| P3 | 別アカウントとして作る（`users.email` の unique を外す） | 同一人物の本棚が2つに割れる。読書管理プロダクトとして最悪 |

### 決め手は可逆性

**P1 → P2 はいつでも変更できるが、P2 → P1 は不可能である。**
一度統合したアカウントを後から分離することはできない。

だから「あとで緩められる方」を先に選ぶ。UX の最良解が P2 だとしても、
不可逆な決定を検証前に入れる理由にはならない。
Auth.js が同等の機能に `allowDangerousEmailAccountLinking` という名前を付けているのも同じ理由である。

IdP のメールを信じて自動紐付けすると、**メール検証の弱いプロバイダ経由で
既存アカウントを乗っ取れる**という具体的な攻撃にもつながる。

### v1 のスコープ

**v1 では 1ユーザー = 1 identity。**
`user_identities` は `(user_id, provider)` の複合ユニークインデックスで
同一プロバイダの二重連携を防いでいるが、**別プロバイダを足せるスキーマになっている**。

明示的な連携フロー（`intent=link`）と連携解除 UI は v2 のスコープ。
**スキーマ変更もデータ移行も不要**で足せる。

---

## username 重複チェック API

| 項目 | 内容 |
|---|---|
| エンドポイント | `GET /v1/users/username/check?value={username}` |
| 認証 | 不要（パブリックエンドポイント） |
| レスポンス | `{ "available": true }` / `{ "available": false }` |
| フロント実装 | デバウンス（300〜500ms）でリクエスト数を抑制 |
| セキュリティ | レートリミットを適用し、username 列挙攻撃を防止 |

---

## signup_token から取得する情報

| クレーム | 取得元 | 用途 |
|---|---|---|
| `provider` | Google / GitHub のどちらか | `user_identities.provider` として保存 |
| `uid` | Google は `id_token` の `sub`、GitHub は `GET /user` の `id` | `user_identities.provider_uid` として保存 |
| `email` | IdP が返した検証済みメール | `users.email` と `user_identities.email` の両方に保存 |
| `name` | IdP の表示名 | nickname 入力欄にプリフィル（**DB には保存しない**） |

---

## 関連ドキュメント

- [認証フロー](./auth.md)
- [ADR 009: 認証方式](../decisions/009-authentication.md)
- [users テーブル定義](./tables/users.md)
- [user_identities テーブル定義](./tables/user_identities.md)

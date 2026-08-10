# 技術スタック選定理由（バックエンド）

## Ruby on Rails (API mode)

### 選定理由
- 新言語・新フレームワークの習得を主目的とした選定
- Java (Spring Boot) / Python (FastAPI) の経験はあるが、Ruby は未経験であり学習価値が高い
- Convention over Configuration の思想により、初期開発速度が高い
- API mode を使用することで、不要なビュー層を排除しフロントエンドとの責務を明確に分離する

### 比較検討した選択肢
| 候補 | 概要 | 外した理由 |
|---|---|---|
| TypeScript (NestJS) | 型安全・モジュール設計 | TypeScript は既存スキルに近く、新言語学習の目的を達成しにくい |

> NestJS は将来の別プロジェクトでの採用候補として引き続き検討する

---

## PostgreSQL

### 選定理由
- 近年のエコシステムで広く推奨されており、採用実績が豊富
- Rails との親和性が高く、ActiveRecord との組み合わせが安定している
- AWS RDS における MySQL のサポート縮小の動向を考慮し、長期運用を見据えて選定
- PaaS (Render / Railway 等) でもデフォルト採用されているケースが多い

---

## 認証：OAuth 2.0（Google / GitHub）+ 自前 JWT

### 選定理由
- ユーザーにパスワード管理を不要にし、ログイン UX を簡素化する
- **認可コードフロー + PKCE(S256) を Rails が所有する。** `client_secret` の保管先を増やさず、
  セッションの所有者を1つに保つ
- IdP から受け取ったトークンは token endpoint から TLS 越しに直接受領するため、
  **JWKS 検証という攻撃面を持たない**
- バックエンド独自の JWT によりステートレスな認証を維持する

比較検討した案（マネージド認証サービス / Auth.js + `id_token` / OmniAuth）と
それぞれを外した理由は [ADR 009: 認証方式](../decisions/009-authentication.md) に記録している。

### 実装方針
- 入口は `GET /auth/:provider` と `GET /auth/:provider/callback`（`/v1` の外）。
  ブラウザのトップレベル遷移で叩かれるため、成否によらず 302 で返す
- 認可コードの交換・本人情報の取り出しはバックエンドが行い、
  **フロントエンドは IdP と直接やりとりしない**
- 独自の JWT（`access_token` / `refresh_token` / `signup_token` / `oauth_state`）を発行し、
  種別は `purpose` クレームで検証する
- プロバイダ差は `lib/oauth/providers/` に閉じる。3つ目を足すときに触るのは
  クラス1個とレジストリ1行だけ

### 使用 gem
| gem | 用途 |
|---|---|
| `jwt` | 4種すべてのトークンの発行・検証 |

**OAuth 移行にあたり gem の追加はゼロである。** 自前プロバイダ層で
`config.api_only = true` を維持するため、OmniAuth は採用していない。

> Devise は API mode では不要な機能が多いため採用しない

### 将来的な拡張
- 1アカウントへの複数プロバイダ連携（`intent=link`）と連携解除 UI。
  `user_identities` は既にこれを表現できるスキーマになっており、
  **スキーマ変更もデータ移行も不要**で足せる

---

## CI/CD：GitHub Actions

### 選定理由
- GitHub リポジトリとの統合がネイティブで設定がシンプル
- 個人開発における運用コストがゼロ（無料枠内で運用可能）
- 自動テスト・Lint・デプロイパイプラインの構築を学習目的として取り組む

---

## 関連ドキュメント
- [認証フロー詳細](./auth.md)
- [外部 API 連携（楽天書籍API）](../api/books/search.md)
- [外部 API との通信層の置き場](../development/directory.md#libclients)
- [アーキテクチャ決定記録](../decisions/README.md)

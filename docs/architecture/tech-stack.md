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

## 認証：Clerk + JWT

### 選定理由
- ユーザーにパスワード管理を不要にし、ログイン UX を簡素化する
- Google OAuth などの外部プロバイダー連携を Clerk に委譲し、認証実装のコストを削減する
- フロントエンドと完全に分離された API として設計するため、フロント主導の認証フローを採用
- バックエンド独自の JWT によりステートレスな認証を維持し、スケーラブルな設計を実現する

### 実装方針
- フロントエンド (Next.js + Clerk SDK) が Google OAuth を処理し、取得した Clerk JWT をバックエンドに送信
- バックエンドが Clerk JWT を検証し、独自の JWT（アクセストークン・リフレッシュトークン）を発行
- セッション管理は行わず、JWT のみで認証を完結させる

### 使用 gem
| gem | 用途 |
|---|---|
| `clerk-sdk-ruby` | Clerk JWT の検証 |
| `jwt` | アクセストークン・リフレッシュトークンの発行・検証 |

> Devise は API mode では不要な機能が多いため採用しない

### 将来的な拡張
- GitHub OAuth の追加を検討（Clerk の設定追加のみで対応可能）

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

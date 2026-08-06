# CLAUDE.md

Ruby on Rails (API mode) + PostgreSQL の JSON API サーバー。

## コマンド

```bash
docker compose exec -e RAILS_ENV=test web bundle exec rspec  # テスト
docker compose exec web bundle exec rubocop                   # Lint
docker compose exec web bundle exec steep check               # 型チェック
docker compose exec web bin/brakeman --no-pager               # セキュリティ
docker compose exec web bin/bundler-audit                     # 依存の脆弱性
```

上記5つが CI（`.github/workflows/ci.yml`）と同じゲート。合否判定は `gate-verifier` が出す。

実装ガイドライン → `docs/development/implementation-guidelines.md`

## 自動ループ

issue をゴールにして実装 → 検証 → PR まで自走する。

- **トリガー**: `/loop`（既定プロンプトは `.claude/loop.md`）または cron
- **1周のゴール**: `agent:pr` の issue を1件、PR を作るところまで。**1周につき1 issue**
- **進捗の正**: `.claude/state/loop.md`。セッションの記憶と食い違ったらこちらを信じる
- **運用ポリシー**: `.claude/rules/loop-policy.md`（停止条件・試行上限・コメント上限）

### 自律度ラベル

**付与・変更は人間の専権事項。** Claude が付け替えてはいけない（deny でも禁止）。

| ラベル | 振る舞い |
|---|---|
| `agent:pr` | 実装 → 検証 → PR 作成まで自走する。マージはしない |
| `agent:draft` | 調査して issue にコメントするのみ。ファイルは作らない |
| `human` | 一切触らない |
| `blocked` | 人間の判断待ち。滞留24h超で報告 |

ラベルなしの issue には着手しない。ラベルなしが多いのは正常な状態。

### スキル

| スキル | 役割 |
|---|---|
| `/agent-issue` | 起票。曖昧な要望を機械判定可能な完了条件に翻訳して issue を作る |
| `/loop-triage` | 観測。issue を1件選び、契約のプレフライト検査をする。**実装しない** |
| `/implement-issue` | 行動。選ばれた issue を実装して PR まで持っていく |
| `/check` | 対話中の軽量チェック（lint + 型 + 規約）。PR 前の合否判定には使わない |
| `/api-spec-review` | API 仕様を人間と壁打ちして確定させる |

ループは `/agent-issue` で起票 → 人間がラベル付与 → `/loop-triage` → `/implement-issue` の順に流れる。
**人間がラベルを付けるまで着手しない。** ここが唯一の人間の必須アクション。

### 強制層（C層）

`.claude/settings.json` の `permissions` と `.claude/hooks/` は**人間が手動で編集する**。
Claude からは編集できない（deny 済み）。

- `db/migrate/` 配下の既存ファイル編集は PreToolUse フックがブロックする
- `gh pr merge` / `gh issue edit` / `gh label` / DB 破壊操作は deny

---
name: check
description: RuboCop（lint）と Steep（型チェック）を実行する
tools: [Bash]
---

lint チェックと型チェックを実行してください。

## 対象ファイル

引数 `$ARGUMENTS` が指定されていればそのファイルを対象にする。指定がない場合は変更されたファイル全体を対象にする。

## 手順

### Step 1: RuboCop（lint）

引数あり:
```bash
docker compose exec web bundle exec rubocop $ARGUMENTS --autocorrect
docker compose exec web bundle exec rubocop $ARGUMENTS
```

引数なし:
```bash
docker compose exec web bundle exec rubocop --autocorrect
docker compose exec web bundle exec rubocop
```

### Step 2: Steep（型チェック）

```bash
docker compose exec web bundle exec steep check
```

## 出力形式

### 全チェック通過の場合

✅ チェック完了 - 問題なし
- RuboCop: パス（自動修正: {n}件）
- Steep: パス

### 失敗がある場合

❌ チェック失敗

**RuboCop:**
- 自動修正済み: {n}件
- 未解決: {n}件
  - {ファイルパス}:{行番号} - {内容}

**Steep:**
- エラー: {n}件
  - {ファイルパス}:{行番号} - {内容}

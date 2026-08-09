#!/bin/bash
# gh issue のラベル操作をブロックする。
# 自律度ラベル（agent:pr / agent:draft / human / blocked）の付与・変更は
# 人間の専権事項（.claude/rules/loop-policy.md §3）。
# 本文・タイトルの編集は許可し、ラベルに触る操作だけを止める。
#
# CLAUDE.md に書くだけでは遵守率 ~80% なので、フックで 100% にする。
#
# -e は付けない。付けると jq の失敗で非ゼロ終了し、
# フック自身の不具合で全ツール呼び出しが止まる。
set -uo pipefail

input=$(cat)

# パースに失敗しても作業を止めない（握り潰して通過させる）
command=$(jq -r '.tool_input.command // ""' <<<"$input" 2>/dev/null) || exit 0

[ -n "$command" ] || exit 0

# gh issue edit / gh issue create 以外は対象外
case "$command" in
  *"gh issue edit"*|*"gh issue create"*) ;;
  *) exit 0 ;;
esac

# ラベル指定のフラグが含まれていなければ通す
grep -qE -- '(--add-label|--remove-label|--label)' <<<"$command" || exit 0

cat >&2 <<MSG
ブロック: gh issue でのラベル操作は禁止されています。
  $command

自律度ラベル（agent:pr / agent:draft / human / blocked）の付与・変更は
人間の専権事項です（.claude/rules/loop-policy.md §3）。

- 起票するときはラベルを付けず、推奨ラベルを1行提案してください
- 本文・タイトルの編集は --body / --body-file / --title で行えます
MSG
exit 2

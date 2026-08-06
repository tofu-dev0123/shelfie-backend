#!/bin/bash
# 適用済みマイグレーションの改変をブロックする。
# 既存の db/migrate/*.rb を書き換えると、開発環境と本番でスキーマが食い違う。
# CLAUDE.md に書くだけでは遵守率 ~80% なので、フックで 100% にする。
#
# -e は付けない。付けると jq の失敗で非ゼロ終了し、
# フック自身の不具合で全ツール呼び出しが止まる。
set -uo pipefail

input=$(cat)

# パースに失敗しても作業を止めない（握り潰して通過させる）
file_path=$(jq -r '.tool_input.file_path // ""' <<<"$input" 2>/dev/null) || exit 0

[ -n "$file_path" ] || exit 0

case "$file_path" in
  *db/migrate/*) ;;
  *) exit 0 ;;
esac

# 新規作成は許可する。ブロックするのは既存ファイルの改変のみ。
[ -e "$file_path" ] || exit 0

cat >&2 <<MSG
ブロック: 適用済みマイグレーションの改変は禁止されています。
  $file_path

スキーマを変更する場合は新しいマイグレーションを作成してください。
既存ファイルをどうしても直す必要がある場合は人間に相談してください。
MSG
exit 2

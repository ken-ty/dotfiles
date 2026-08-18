#!/bin/bash

# mcp/doctor.sh
#
# servers.json の宣言と、実際に登録されている MCP サーバのズレを報告します。
# 何も変更しません。読み取りだけです。

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVERS_JSON="$SCRIPT_DIR/servers.json"

has() { type "$1" > /dev/null 2>&1; }
expand_home() { printf '%s' "${1//\$HOME/$HOME}"; }

for cmd in claude jq; do
    has "$cmd" || { echo "ERROR: $cmd が見つかりません。" >&2; exit 1; }
done

# list_servers: カレントディレクトリから見える登録状況を name<TAB>status で出す
list_servers() {
    claude mcp list 2>/dev/null \
        | grep -E ' - (✔|✘)' \
        | sed -E 's/^(.+): .* - (.*)$/\1\t\2/'
}

# report: 1 サーバの状態を 1 行で出す
report() {
    local name="$1" haystack="$2" suffix="${3:-}"
    local line status
    line=$(grep -F "$(printf '%s\t' "$name")" <<< "$haystack" || true)
    if [ -z "$line" ]; then
        echo "  MISSING  $name $suffix"
        return
    fi
    status=$(cut -f2 <<< "$line")
    case "$status" in
        *Connected*) echo "  OK       $name $suffix" ;;
        *)           echo "  FAILED   $name  ($status)" ;;
    esac
}

here=$(list_servers)

echo "== user スコープ =="
while IFS= read -r name; do
    [ -z "$name" ] && continue
    report "$name" "$here"
done < <(jq -r '.user[].name' "$SERVERS_JSON")

echo "== project スコープ =="
while IFS= read -r entry; do
    name=$(jq -r '.name' <<< "$entry")
    path=$(expand_home "$(jq -r '.path' <<< "$entry")")
    if [ ! -d "$path" ]; then
        echo "  SKIP     $name (ディレクトリが無い: $path)"
        continue
    fi
    # そのディレクトリから見ないと project スコープは見えない
    there=$( cd "$path" && list_servers )
    report "$name" "$there" "($path)"
done < <(jq -c '.project[]' "$SERVERS_JSON")

echo "== claude.ai コネクタ =="
while IFS= read -r name; do
    [ -z "$name" ] && continue
    report "$name" "$here"
done < <(jq -r '.connectors.names[]' "$SERVERS_JSON")

echo "== 宣言に無いもの (ドリフト) =="
declared=$(jq -r '[.user[].name] + .connectors.names | .[]' "$SERVERS_JSON")
found_drift=0
while IFS= read -r line; do
    [ -z "$line" ] && continue
    name=$(cut -f1 <<< "$line")
    if ! grep -qxF "$name" <<< "$declared"; then
        echo "  UNDECLARED  $name"
        found_drift=1
    fi
done <<< "$here"
[ "$found_drift" -eq 0 ] && echo "  なし"

cat <<'NOTE'

-- 検知できないこと --------------------------------------------------
このスクリプトが見ているのは「設定と接続状態」までです。
claude mcp list が ✔ Connected でも、セッションに mcp__* ツールが
1つも降りてこないことがあります (claude.ai コネクタでたまに起きる)。
それはセッションの内側からしか分からないので、ここでは検知できません。

  症状: ツール一覧に mcp__*notion* 等が無い / 未認証扱いになる
  対処: claude mcp login '<name>'  または claude.ai のコネクタ設定
  回避: 読み取りだけなら Chrome MCP 経由で代替できる
---------------------------------------------------------------------
NOTE

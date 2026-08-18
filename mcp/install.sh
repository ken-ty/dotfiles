#!/bin/bash

# mcp/install.sh
#
# servers.json の宣言どおりに Claude Code の MCP サーバを配線します。
# 冪等です。既にあるサーバには触りません。
#
# claude.ai コネクタ (Notion / Gmail / Slack / …) は OAuth トークンが実体なので
# 設定からは復元できません。チェックリストとして表示するだけです。

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVERS_JSON="$SCRIPT_DIR/servers.json"

# has: コマンドが存在するかチェック
has() { type "$1" > /dev/null 2>&1; }

# expand_home: 文字列中の $HOME を実パスに展開
expand_home() { printf '%s' "${1//\$HOME/$HOME}"; }

# server_exists: 指定名の MCP サーバが既に登録されているか
server_exists() { claude mcp get "$1" > /dev/null 2>&1; }

for cmd in claude jq; do
    has "$cmd" || { echo "ERROR: $cmd が見つかりません。" >&2; exit 1; }
done
[ -f "$SERVERS_JSON" ] || { echo "ERROR: $SERVERS_JSON が見つかりません。" >&2; exit 1; }

added=0
skipped=0
warned=0

# -----------------------------------------------
# user スコープ (全プロジェクトで有効)
# -----------------------------------------------
echo "== user スコープ =="

while IFS= read -r entry; do
    name=$(jq -r '.name' <<< "$entry")
    optional=$(jq -r '.optional // false' <<< "$entry")
    requires=$(jq -r '.requires_file // empty' <<< "$entry")

    if server_exists "$name"; then
        echo "  = $name (登録済み)"
        skipped=$((skipped + 1))
        continue
    fi

    # 実体が無い任意サーバは飛ばす (別マシン / 拡張未インストール)
    if [ "$optional" = "true" ] && [ -n "$requires" ]; then
        if [ ! -e "$(expand_home "$requires")" ]; then
            echo "  - $name (実体が無いので飛ばす: $requires)"
            skipped=$((skipped + 1))
            continue
        fi
    fi

    # Keychain に秘密が入っているか先に確かめる
    missing_secret=""
    while IFS= read -r secret; do
        [ -z "$secret" ] && continue
        if ! security find-generic-password -a "$USER" -s "$secret" -w > /dev/null 2>&1; then
            missing_secret="$secret"
        fi
    done < <(jq -r '.secrets // [] | .[]' <<< "$entry")

    if [ -n "$missing_secret" ]; then
        echo "  ! $name: Keychain に $missing_secret がありません。先に登録してください:"
        echo "      security add-generic-password -a \"\$USER\" -s $missing_secret -w"
        warned=$((warned + 1))
        continue
    fi

    config=$(jq -c --arg home "$HOME" '.config | walk(if type == "string" then gsub("\\$HOME"; $home) else . end)' <<< "$entry")
    claude mcp add-json "$name" "$config" --scope user > /dev/null
    echo "  + $name (追加)"
    added=$((added + 1))
done < <(jq -c '.user[]' "$SERVERS_JSON")

# -----------------------------------------------
# project スコープ (そのディレクトリでのみ有効)
# -----------------------------------------------
echo "== project スコープ =="

while IFS= read -r entry; do
    name=$(jq -r '.name' <<< "$entry")
    path=$(expand_home "$(jq -r '.path' <<< "$entry")")

    if [ ! -d "$path" ]; then
        echo "  - $name (ディレクトリが無いので飛ばす: $path)"
        skipped=$((skipped + 1))
        continue
    fi

    if ( cd "$path" && server_exists "$name" ); then
        echo "  = $name (登録済み: $path)"
        skipped=$((skipped + 1))
        continue
    fi

    config=$(jq -c --arg home "$HOME" '.config | walk(if type == "string" then gsub("\\$HOME"; $home) else . end)' <<< "$entry")
    ( cd "$path" && claude mcp add-json "$name" "$config" --scope local > /dev/null )
    echo "  + $name (追加: $path)"
    added=$((added + 1))
done < <(jq -c '.project[]' "$SERVERS_JSON")

# -----------------------------------------------
# claude.ai コネクタ (手動)
# -----------------------------------------------
echo "== claude.ai コネクタ (自動配線できません) =="
echo "  OAuth トークンが実体なので、設定ファイルからは復元できません。"
echo "  未接続のものがあれば、対話セッションで次を実行してください:"
while IFS= read -r conn; do
    if server_exists "$conn"; then
        echo "    = $conn"
    else
        echo "    ! $conn  ->  claude mcp login '$conn'"
        warned=$((warned + 1))
    fi
done < <(jq -r '.connectors.names[]' "$SERVERS_JSON")

echo
echo "追加 $added / 据え置き $skipped / 要対応 $warned"

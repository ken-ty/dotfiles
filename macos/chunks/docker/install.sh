#!/bin/bash
# docker の後処理: brew の cli-plugins (buildx / compose) を docker CLI に見つけさせる。
# ~/.docker/config.json は認証情報も持つので、jq で該当キーだけ足す。
set -eu
export PATH="/opt/homebrew/bin:$PATH"
if [ -d /Applications/Docker.app ]; then
    echo "SKIP: Docker Desktop が入っている。colima と同居させない (先にアンインストールする)" >&2
    exit 0
fi
cfg="$HOME/.docker/config.json"
plugins="$(brew --prefix)/lib/docker/cli-plugins"
mkdir -p "$(dirname "$cfg")"
[ -f "$cfg" ] || echo '{}' > "$cfg"
tmp="$(mktemp)"
jq --arg p "$plugins" '.cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$p] | unique)' "$cfg" > "$tmp" && mv "$tmp" "$cfg"

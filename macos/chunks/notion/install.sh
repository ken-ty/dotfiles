#!/bin/bash
# Notion の公式 CLI `ntn` を入れる / 更新する。
#
# 公式の入れ方は curl の script か npm だけで、Homebrew の formula / cask は無い (2026-09 時点、
# https://developers.notion.com/cli/get-started/installation)。brew に載ったらこのファイルを消して
# Brewfile に 1 行書く。
#
# 入れる先は ~/.local/bin/ntn (script の既定)。.zshrc が ~/.local/bin を PATH に持つこと。
# 何度実行しても同じ結果: 無ければ入れ、あれば `ntn update` で最新にする。
set -eu
if command -v ntn >/dev/null 2>&1; then
    ntn update
else
    curl -fsSL https://ntn.dev | bash
fi
# ログインは人がやる (ブラウザで承認が要る)。無人で回す機械には入れない
command -v ntn >/dev/null 2>&1 || export PATH="$HOME/.local/bin:$PATH"
ntn whoami >/dev/null 2>&1 || echo "ntn: まだログインしていない。'ntn login' を実行する"

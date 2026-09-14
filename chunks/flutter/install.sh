#!/bin/bash
# flutter の後処理: asdf の flutter プラグインと、~/.tool-versions に書いてある版を入れる。
set -eu
export PATH="/opt/homebrew/bin:$PATH"
asdf plugin list 2>/dev/null | grep -qx flutter || asdf plugin add flutter
(cd "$HOME" && asdf install flutter)

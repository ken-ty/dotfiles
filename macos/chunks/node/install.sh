#!/bin/bash
# node の後処理: asdf の nodejs プラグインと、~/.tool-versions に書いてある版を入れる。
# asdf 0.16 以降は `asdf global` が無く、$HOME/.tool-versions がグローバル。
set -eu
export PATH="/opt/homebrew/bin:$PATH"
asdf plugin list 2>/dev/null | grep -qx nodejs || asdf plugin add nodejs
(cd "$HOME" && asdf install nodejs)

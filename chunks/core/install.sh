#!/bin/bash
# core の後処理: fzf のキーバインド (~/.fzf.zsh) を作る。.zshrc がこれを source する。
set -eu
fzf_install="$(brew --prefix)/opt/fzf/install"
if [ -x "$fzf_install" ] && [ ! -f "$HOME/.fzf.zsh" ]; then
    "$fzf_install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

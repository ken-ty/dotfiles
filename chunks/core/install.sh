#!/bin/bash
# core の後処理: fzf のキーバインド (~/.fzf.zsh) を作る。.zshrc がこれを source する。
#
# ~/.fzf.zsh は fzf の置き場所 (bin と shell/) を絶対パスで指す。brew 以外で入れた fzf
# (git clone した checkout など) を消すと、ファイルだけ残って壊れた場所を指し続け、
# シェル起動のたびに "no such file or directory: .../shell/key-bindings.zsh" が出る。
# 無いときだけでなく、指している先が消えているときも作り直す。
set -eu
fzf_install="$(brew --prefix)/opt/fzf/install"
fzf_zsh="$HOME/.fzf.zsh"

[ -x "$fzf_install" ] || exit 0

if [ -f "$fzf_zsh" ]; then
    # fzf の installer が書く行 `source "<fzf>/shell/key-bindings.zsh"` から置き場所を読む
    key_bindings=$(sed -n 's/^source "\(.*\/shell\/key-bindings\.zsh\)".*/\1/p' "$fzf_zsh" | head -n 1)
    if [ -z "$key_bindings" ] || [ -f "$key_bindings" ]; then
        # 自前の ~/.fzf.zsh か、生きている installer 製。触らない
        exit 0
    fi
    echo "~/.fzf.zsh が無い場所を指している ($key_bindings)。作り直す"
fi
"$fzf_install" --key-bindings --completion --no-update-rc --no-bash --no-fish

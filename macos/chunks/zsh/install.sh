#!/bin/bash
# zsh の後処理: compinit の安全確認 (compaudit) を通す。
# brew は share/ を admin グループ書き込み可 (775) にすることがあり、そのままだと
# .zshrc の compinit が "insecure directories" で止まって補完が効かない。
# brew 自身が zsh-completions の caveats で案内している chmod と同じ。
set -eu
prefix="$(brew --prefix)"
for d in "$prefix/share" "$prefix/share/zsh" "$prefix/share/zsh/site-functions" "$prefix/share/zsh-completions"; do
    [ -d "$d" ] && chmod go-w "$d"
done
# 補完のキャッシュ (~/.zcompdump) は fpath が変わると古くなるので捨てる。次の起動で作り直される
rm -f "$HOME"/.zcompdump*
echo "compaudit:"; zsh -c 'fpath=("'"$prefix"'/share/zsh-completions" $fpath); autoload -Uz compaudit; compaudit' && echo "  clean"

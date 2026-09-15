# 履歴を fzf で曖昧検索して、選んだコマンドをバッファに置く (dotfiles 自前版)。
# fzf 付属の fzf-history-widget と同じ用途。keybindings.conf ではそちらを on にしている。
function fzf-select-history() {
  if ! command -v fzf >/dev/null 2>&1; then
    zle -M 'fzf が無い (brew install fzf)'
    return 1
  fi
  BUFFER=$(\history -n -r 1 | fzf --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N fzf-select-history

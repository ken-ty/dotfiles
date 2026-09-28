# ^] で ghq list の結果を fzf で曖昧検索して、選んだリポジトリに cd する。
# ghq については https://github.com/Songmu/ghq-handbook/blob/master/ja/01-introduction.md
function cd-ghq-list--fzf() {
  if ! command -v fzf >/dev/null 2>&1; then
    zle -M 'fzf が無い (brew install fzf)'   # 無言で画面が消える事故を防ぐ
    return 1
  fi
  local selected_dir=$(ghq list -p | fzf --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N cd-ghq-list--fzf

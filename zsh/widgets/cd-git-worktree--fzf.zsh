# ^K で今のリポジトリの worktree を fzf で曖昧検索して、選んだ worktree に cd する。
# K は「切り替え (Kirikae)」。^] (cd-ghq-list--fzf) がリポジトリ間の移動、こちらはリポジトリ内の移動。
function cd-git-worktree--fzf() {
  if ! command -v fzf >/dev/null 2>&1; then
    zle -M 'fzf が無い (brew install fzf)'   # 無言で画面が消える事故を防ぐ
    return 1
  fi
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    zle -M 'git リポジトリの中ではない (リポジトリ間の移動は ^])'
    return 1
  fi
  local selected_dir=$(git worktree list | fzf --query "$LBUFFER" | awk '{print $1}')
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N cd-git-worktree--fzf

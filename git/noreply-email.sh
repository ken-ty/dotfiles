#!/bin/bash

# git/noreply-email.sh
#
# コミットに載るメールを GitHub の noreply (<id>+<login>@users.noreply.github.com) にそろえます。
# 値は gh で引くので、このリポジトリに個人のメールは書きません。fork した人が流せば、
# その人の noreply が入ります。install.sh の Step 3 から呼ばれます。単独でも流せます。
#
#   bash git/noreply-email.sh            # 既定は ~/.gitconfig.local に書く
#   bash git/noreply-email.sh <file>     # 書き込み先を変える
#
# 何をするか:
#   user.email が無い           → gh api user から noreply を組み立てて書く。user.name が無ければ login も書く
#   user.email が既に noreply    → 何もしない (何度流しても同じ)
#   user.email が noreply 以外   → 書き換えずに表示して止まる (先方指定のメールなどを壊さない)
#   gh が無い / 未ログイン      → 何もせず案内だけ出す
#
# どの場合も終了コードは 0。install.sh を途中で止めないため。

set -eu

case "${1:-}" in
    -h|--help) sed -n '3,19p' "$0"; exit 0 ;;
esac

file="${1:-$HOME/.gitconfig.local}"
suffix="@users.noreply.github.com"

current=$(git config --file "$file" --get user.email || true)

case "$current" in
    *"$suffix")
        echo "git user.email: already noreply (${current})."
        exit 0
        ;;
    ?*)
        echo "git user.email: ${current} が入っているので書き換えません。"
        echo "  noreply にそろえるなら、消してからもう一度流します:"
        echo "    git config --file \"${file}\" --unset user.email"
        echo "    bash \$HOME/dotfiles/git/noreply-email.sh"
        exit 0
        ;;
esac

if ! type gh > /dev/null 2>&1 || ! gh auth status > /dev/null 2>&1; then
    echo "git user.email: 未設定。gh にログインしていないので noreply を引けません。"
    echo "  gh auth login のあと: bash \$HOME/dotfiles/git/noreply-email.sh"
    exit 0
fi

if ! user=$(gh api user --jq '"\(.id) \(.login)"'); then
    echo "git user.email: gh api user が失敗しました。後で流し直してください:"
    echo "  bash \$HOME/dotfiles/git/noreply-email.sh"
    exit 0
fi
id=${user% *}
login=${user#* }

git config --file "$file" user.email "${id}+${login}${suffix}"
echo "git user.email: set ${id}+${login}${suffix}"

if [ -z "$(git config --file "$file" --get user.name || true)" ]; then
    git config --file "$file" user.name "$login"
    echo "git user.name: set ${login}"
fi

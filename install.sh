#!/bin/bash

# install.sh
#
# dotfiles を取ってきて設定ファイルを適用し、選んだ「チャンク」(技術のひと塊) を Homebrew で入れます。
# 既存の設定ファイルは backup フォルダに移動します。
# backup から復元可能ですが、複数回実行すると上書きされるため注意。
#
#   bash install.sh                        # 対話。設定ファイルは 1 つずつ聞き、チャンクは 3 択
#   bash install.sh --mode recommended     # 推奨チャンクだけ (chunks/recommended)
#   bash install.sh --mode full            # 全チャンク
#   bash install.sh --mode select          # チャンクを 1 つずつ選ぶ
#   bash install.sh --mode recommended --yes   # 何も聞かない (サーバー向け)
#
# チャンクは chunks/<名前>/Brewfile (+ 任意の install.sh)。1 行目の "# desc:" が一覧に出る。

set -eu

# -----------------------------------------------
# 設定と共通関数
# -----------------------------------------------

# dotfiles を格納するディレクトリ
DOT_DIR="$HOME/dotfiles"

# バックアップ用ディレクトリ
BACKUP_DIR="$HOME/dotfiles_backup"

# 引数
MODE=""        # recommended / full / select / "" (対話で聞く)
YES=false      # true なら prompt_setup は聞かずに yes

while [ $# -gt 0 ]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        --mode=*) MODE="${1#--mode=}"; shift ;;
        --yes|-y) YES=true; shift ;;
        -h|--help) sed -n '3,15p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done
case "$MODE" in
    ""|recommended|full|select) ;;
    *) echo "--mode は recommended / full / select のどれか" >&2; exit 2 ;;
esac

# has: コマンドが存在するかチェック
# 引数: コマンド名
# 戻り値: 0 (コマンドが存在する場合), 1 (存在しない場合)
has() { type "$1" > /dev/null 2>&1; }

# prompt_setup: ユーザーにセットアップの実行可否を問い合わせる
# 引数: 設定項目名, 既定の答え (y か n。省略時 n)
# 戻り値: 0 (yes), 1 (no)。--yes のときは聞かずに 0
prompt_setup() {
    local default="${2:-n}"
    $YES && return 0
    if [ "$default" = "y" ]; then echo "Do you want to setup $1? [Y/n]"; else echo "Do you want to setup $1? [y/N]"; fi
    while :; do
        read -r answer
        case $answer in
            [yY] | [yY][eE][sS]) return 0 ;;
            [nN] | [nN][oO]) return 1 ;;
            '') [ "$default" = "y" ] && return 0 || return 1 ;;
            *) echo "Invalid input. Please type 'y' or 'n'."; ;;
        esac
    done
}

# error_exit: エラー発生時にエラーメッセージを表示して終了
# 引数:
#   $1: エラーコード
#   $2: エラー要約
#   $3: 詳細メッセージ
# 動作: 標準エラー出力にメッセージを表示し、スクリプトを終了
error_exit() {
    echo -e "\nError ($1): $2\n$3" >&2
    exit 1
}

# get_os_name: 現在の OS 名を判定
# 戻り値: "Mac" または "Ubuntu" (サポート外の場合はエラー終了)
get_os_name() {
    case "$(uname)" in
        Darwin) echo "Mac" ;;
        Linux)
            if grep -q '^NAME="Ubuntu' /etc/os-release; then
                echo "Ubuntu"
            else
                error_exit "0100" "Unsupported OS" "This script supports only Mac and Ubuntu."
            fi
            ;;
        *) error_exit "0100" "Unsupported OS" "This script supports only Mac and Ubuntu." ;;
    esac
}

# Windows は uname が MINGW64_NT-... を返すので get_os_name まで進めば落ちるが、
# そこに着く前に Step 2 の tar 展開や ln -s が中途半端に走ってしまう。しかも
# "Unsupported OS" だけでは Windows 用の入口があることが分からない。先に案内して止める。
case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)
        error_exit "0102" "This is Windows" \
        "Use the PowerShell installer instead:\n\n    powershell -ExecutionPolicy Bypass -File install.ps1"
        ;;
esac

# backup_and_link: ファイルのバックアップを作成し、シンボリックリンクを作成
# 引数:
#   $1: 元ファイルのパス (ソース)
#   $2: 作成するリンクのパス (デスティネーション)
#   $3: 設定項目の名前 (ユーザー表示用)
# 元ファイルが repo に無ければ何もしない (壊れたリンクを作らない)。
# 既に同じ場所を指すリンクなら何もしない (何度実行しても同じ結果)。
backup_and_link() {
    local src=$1
    local dest=$2
    local name=$3

    [ -e "$src" ] || { echo "SKIP: $name ($src が無い)"; return 0; }
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "$name: already linked."
        return 0
    fi
    if prompt_setup "$name" y; then
        echo "Setting up $name..."
        # 既存の設定ファイルをバックアップ
        [ -e "$dest" ] && mkdir -p "$(dirname "$BACKUP_DIR/$dest")" && mv "$dest" "$BACKUP_DIR/$dest" && echo "Backup created at: $BACKUP_DIR/$dest"
        # シンボリックリンクを作成
        mkdir -p "$(dirname "$dest")"
        ln -sf "$src" "$dest"
        echo "$name setup complete."
    fi
}

# chunk_desc: チャンクの説明 (Brewfile 1 行目の "# desc:")
chunk_desc() { sed -n '1s/^# desc: *//p' "$DOT_DIR/chunks/$1/Brewfile"; }

# all_chunks: chunks/ 配下の全チャンク名 (アルファベット順)
all_chunks() { find "$DOT_DIR/chunks" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort; }

# install_chunk: Brewfile を bundle し、install.sh があれば実行する
install_chunk() {
    local c=$1
    echo "----- chunk: $c — $(chunk_desc "$c")"
    brew bundle --file="$DOT_DIR/chunks/$c/Brewfile"
    [ -f "$DOT_DIR/chunks/$c/install.sh" ] && bash "$DOT_DIR/chunks/$c/install.sh"
    return 0
}

# -----------------------------------------------
# メイン処理
# -----------------------------------------------

# バックアップディレクトリ作成
echo "==================================="
echo "Step 1: Creating backup directory"
echo "==================================="
mkdir -p "$BACKUP_DIR"
echo "Backup directory: $BACKUP_DIR"

# dotfiles のダウンロード
echo "==================================="
echo "Step 2: Downloading dotfiles"
echo "==================================="
if [ -e "$DOT_DIR/.git" ]; then
    # git で clone 済み (ghq 配下への symlink を含む)。そのまま使う。更新は git pull で
    echo "dotfiles already exists as a git checkout: $(cd "$DOT_DIR" && git rev-parse --short HEAD) ($(cd "$DOT_DIR" && git rev-parse --abbrev-ref HEAD))"
elif [ -d "$DOT_DIR" ]; then
    error_exit "0101" "dotfiles already exists!" \
    "You should backup \"\$HOME/dotfiles\" and execute the following command:\n\n    rm -rf \$HOME/dotfiles"
elif has git; then
    git clone https://github.com/ken-ty/dotfiles.git "$DOT_DIR"
    echo "dotfiles cloned."
else
    TARBALL="https://github.com/ken-ty/dotfiles/archive/main.tar.gz"
    curl -L --progress-bar "$TARBALL" -o main.tar.gz
    tar -zxvf main.tar.gz
    rm -f main.tar.gz
    mv -f dotfiles-main "$DOT_DIR"
    echo "dotfiles downloaded (git が無いので tarball。後で git を入れたら clone し直すと更新できる)."
fi

# dotfiles のリンク作成
echo "==================================="
echo "Step 3: Creating dotfiles symlinks"
echo "==================================="

os_name=$(get_os_name)

# Home ディレクトリ用ファイル
backup_and_link "$DOT_DIR/.zshrc" "$HOME/.zshrc" ".zshrc"

# asdf の設定
for asdf_file in ".tool-versions" ".default-gems"; do
    backup_and_link "$DOT_DIR/asdf/$asdf_file" "$HOME/$asdf_file" "$asdf_file"
done

# Git の設定
backup_and_link "$DOT_DIR/git/.gitconfig" "$HOME/.gitconfig" "Git config"
# .gitconfig の include は「~/.gitconfig からの相対」で解決される (symlink を辿らない) ので、
# ~/.gitconfig.local も張る。中身は機械ごと (gh の credential helper など)。無ければ空で作る
[ -e "$DOT_DIR/git/.gitconfig.local" ] || touch "$DOT_DIR/git/.gitconfig.local"
backup_and_link "$DOT_DIR/git/.gitconfig.local" "$HOME/.gitconfig.local" "Git config (local)"
# グローバル gitignore。~/.config/git/ignore は git が既定で読む場所 (XDG) なので
# .gitconfig に core.excludesfile は書かない
backup_and_link "$DOT_DIR/git/ignore" "$HOME/.config/git/ignore" "Git global ignore"

# VSCode の設定 (--yes のときは飛ばす。サーバーに VSCode は無い)
if ! $YES; then
    vscode_dest=""
    if [ "$os_name" == "Mac" ]; then
        vscode_dest="$HOME/Library/Application Support/Code/User/settings.json"
    elif [ "$os_name" == "Ubuntu" ]; then
        vscode_dest="$HOME/.config/Code/User/settings.json"
    fi
    backup_and_link "$DOT_DIR/vscode/settings.json" "$vscode_dest" "VSCode settings.json"
fi

# Homebrew とチャンク
echo "==================================="
echo "Step 4: Homebrew & chunks"
echo "==================================="
if [ "$os_name" == "Mac" ]; then
    if ! has brew; then
        [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    if ! has brew; then
        if prompt_setup "Homebrew" y; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
fi
if has brew; then
    if [ -z "$MODE" ]; then
        echo "How much do you want to install?"
        echo "  1) recommended — $(tr '\n' ' ' < "$DOT_DIR/chunks/recommended")"
        echo "  2) full        — $(all_chunks | tr '\n' ' ')"
        echo "  3) select      — 1 つずつ選ぶ"
        echo "  n) skip"
        read -r answer
        case $answer in
            1) MODE=recommended ;;
            2) MODE=full ;;
            3) MODE=select ;;
            *) MODE=skip ;;
        esac
    fi
    chunks=""
    case "$MODE" in
        recommended) chunks=$(cat "$DOT_DIR/chunks/recommended") ;;
        full) chunks=$(all_chunks) ;;
        select)
            for c in $(all_chunks); do
                default=n
                grep -qx "$c" "$DOT_DIR/chunks/recommended" && default=y
                echo "  $c — $(chunk_desc "$c")"
                prompt_setup "chunk $c" "$default" && chunks="$chunks $c"
            done
            ;;
        skip) echo "Skipping chunks." ;;
    esac
    for c in $chunks; do install_chunk "$c"; done
else
    echo "Homebrew が無いのでチャンクは入れません。"
fi

# macOS のシステム設定 (defaults)。サーバー (--yes) では触らない
if [ "$os_name" == "Mac" ] && ! $YES && prompt_setup "macOS defaults"; then
    bash "$DOT_DIR/macos/defaults.sh"
fi

echo -e "\nAll steps completed successfully!"
echo
echo "AI エージェントのスキルはここでは入れません。必要なら別途:"
echo "  https://github.com/ken-ty/agent-skills"

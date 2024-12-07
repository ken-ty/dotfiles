#!/bin/bash

# install.sh
# 
# 最新の origin/main から dotfiles をダウンロードし、設定ファイルを適用します。
# 既存の設定ファイルは backup フォルダに移動します。
# backup から復元可能ですが、複数回実行すると上書きされるため注意。

set -eu

# -----------------------------------------------
# 設定と共通関数
# -----------------------------------------------

# dotfiles を格納するディレクトリ
DOT_DIR="$HOME/dotfiles"

# バックアップ用ディレクトリ
BACKUP_DIR="$HOME/dotfiles_backup"

# has: コマンドが存在するかチェック
# 引数: コマンド名
# 戻り値: 0 (コマンドが存在する場合), 1 (存在しない場合)
has() { type "$1" > /dev/null 2>&1; }

# prompt_setup: ユーザーにセットアップの実行可否を問い合わせる
# 引数: 設定項目名
# 戻り値: 0 (ユーザーが "yes" または "y" を入力した場合), 1 (それ以外)
prompt_setup() {
    echo "Do you want to setup $1? [y/N]"
    while :; do
        read -r answer
        case $answer in
            [yY] | [yY][eE][sS]) return 0 ;;
            [nN] | [nN][oO] | '') return 1 ;;
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

# backup_and_link: ファイルのバックアップを作成し、シンボリックリンクを作成
# 引数:
#   $1: 元ファイルのパス (ソース)
#   $2: 作成するリンクのパス (デスティネーション)
#   $3: 設定項目の名前 (ユーザー表示用)
backup_and_link() {
    local src=$1
    local dest=$2
    local name=$3

    if prompt_setup "$name"; then
        echo "Setting up $name..."
        # 既存の設定ファイルをバックアップ
        [ -e "$dest" ] && mkdir -p "$(dirname "$BACKUP_DIR/$dest")" && mv "$dest" "$BACKUP_DIR/$dest" && echo "Backup created at: $BACKUP_DIR/$dest"
        # シンボリックリンクを作成
        ln -sf "$src" "$dest"
        echo "$name setup complete."
    fi
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
if [ ! -d "$DOT_DIR" ]; then
    TARBALL="https://github.com/ken-ty/dotfiles/archive/main.tar.gz"
    curl -L --progress-bar "$TARBALL" -o main.tar.gz
    tar -zxvf main.tar.gz
    rm -f main.tar.gz
    mv -f dotfiles-main "$DOT_DIR"
    echo "dotfiles downloaded."
else
    error_exit "0101" "dotfiles directory already exists" "Please backup and remove $DOT_DIR before running the script."
fi

# dotfiles のリンク作成
echo "==================================="
echo "Step 3: Creating dotfiles symlinks"
echo "==================================="

# Home ディレクトリ用ファイル
for file in ".zshrc"; do
    backup_and_link "$DOT_DIR/$file" "$HOME/$file" "$file"
done

# VSCode の設定
os_name=$(get_os_name)
vscode_dest=""
if [ "$os_name" == "Mac" ]; then
    vscode_dest="$HOME/Library/Application Support/Code/User/settings.json"
elif [ "$os_name" == "Ubuntu" ]; then
    vscode_dest="$HOME/.config/Code/User/settings.json"
fi
backup_and_link "$DOT_DIR/vscode/settings.json" "$vscode_dest" "VSCode settings.json"

# VSCode 拡張機能
vscode_extensions="$DOT_DIR/vscode/my_vscode_extensions.sh"
if prompt_setup "VSCode extensions"; then
    echo "Importing VSCode extensions..."
    set +e
    source "$vscode_extensions"
    set -e
    echo "VSCode extensions imported."
fi

# asdf の設定
for asdf_file in ".tool-versions" ".default-gems"; do
    backup_and_link "$DOT_DIR/asdf/$asdf_file" "$HOME/$asdf_file" "$asdf_file"
done

# Git の設定
backup_and_link "$DOT_DIR/git/.gitconfig" "$HOME/.gitconfig" "Git config"

echo -e "\nAll steps completed successfully!"

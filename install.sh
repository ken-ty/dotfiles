#!/bin/bash

# install.sh
# 
# このスプリプトを実行すると最新の origin/main から
# dotfiles で管理している各設定ファイルを適用します.
# 
# もし既に設定ファイルがが存在したら, backupフォルダに移動します.
# 動作がおかしかったら backup から復元して下さい.
# 但し複数回 install.sh を実行すると backup がが上書きされるので注意.

set -eu # エラーが発生した場合や未定義の変数が使用された場合にスクリプトの実行を終了する

# 変数 ここから {{{
    DOT_DIR="$HOME/dotfiles" # dotfile を 格納するディレクトリ
    BACKUP_DIR="$HOME/dotfiles_backup" # backup を 格納するディレクトリ
# }}} 変数 ここまで

# 関数宣言 ここから {{{
    # コマンドが存在するかチェック
    has() {
        type "$1" > /dev/null 2>&1
    }

    # セットアップを実行するかどうかユーザーに入力させる
    is_setup() {
        echo "Do you setup $1? [y/N]"
        while :
        do
            read -r answer
            case $answer in
            'yes' | 'y') return 0 ;;
            [nN]o | [nN]) return 1 ;;
            *) echo "Try again because you input incorrect letter. Do you setup $1? [y/N]" ;;
            esac
        done
    }

    # エラー終了する
    # 
    # Usage: error $id $summary $discription
    error() {
        echo -e "\nE($1): $2\n"
        echo -e $3
        exit 1
    }

    # 判定したOS名を返す
    get_os_name() {
        declare OS="unsupported os"
        if [ "$(uname)" == 'Darwin' ]; then
        return 1
        OS='Mac'
        elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
        RELEASE_FILE=/etc/os-release
        if grep '^NAME="Ubuntu' "${RELEASE_FILE}" >/dev/null; then
        OS=Ubuntu
        else
            echo "Your platform is not supported."
            uname -a
            return 1
        fi
        else
        echo "Your platform is not supported."
        uname -a
        return 1
        fi

        echo $OS
    }
# }}} 関数宣言 ここまで

# バックアップファイルを作成する ここから {{{
    echo "バックアップファイルを作成します."
    if [ ! -d ${BACKUP_DIR} ]; then    
        mkdir $BACKUP_DIR
        echo "$BACKUP_DIR を作成しました."
    else
        echo "$BACKUP_DIR は既に存在します."
    fi
    echo "バックアップは $BACKUP_DIR に格納されます."
# }}} バックアップファイルを作成する ここまで

# dotfiles のダウンロード ここから {{{
    echo -e "\ndotfiles をダウンロードします."
    if [ ! -d ${DOT_DIR} ]; then
        TARBALL="https://github.com/ken-ty/dotfiles/archive/main.tar.gz"
        curl -L ${TARBALL} -o main.tar.gz # mac なら curl が入っているはず
        tar -zxvf main.tar.gz # mac なら tar が入ってるはず ( linux の gnu-tar とは挙動異なるので注意 )
        rm -f main.tar.gz
        mv -f dotfiles-main $DOT_DIR
        echo "dotfiles をダウンロードしました."
    else
        error "0101" "dotfiles already exists!" "you should backup \"\$HOME/dotfiles\" and execute delete command \"rm -rf \$HOME/dotfiles\""
    fi
# }}} dotfiles のダウンロード ここまで

# dotfile のリンク作成 ここから {{{
    echo -e "\ndotfiles のリンクを作成します."

    # $HOME にリンクを作成するitem
    home_files=(".zshrc")
    for file in "${home_files[@]}" ; do
        if is_setup "$file"; then
            echo -e "\n$file のリンクを作成します."

            [ -e $HOME/$file ] && mv "$HOME/$file" "$BACKUP_DIR/$file" # バックアップ

            ln -sf "$DOT_DIR/$file" "$HOME/$file" # リンク作成
            echo "$file のリンクを作成しました."
        fi
    done

    # vscode の settings.json
    display_name="vscode > settings.json"
    src="$DOT_DIR/vscode/settings.json"
    dist="" # see: https://code.visualstudio.com/docs/getstarted/settings#_settings-file-locations
    if [ "$(get_os_name)" == "Mac" ]; then
        dist="$HOME/Library/Application Support/Code/User/settings.json"
    elif [ "$(get_os_name)" == "Ubuntu" ]; then
        dist="$HOME/.config/Code/User/settings.json"
    else
        error "0102" "Unsupported OS" "Your platform is not supported."
    fi
    if is_setup "$display_name"; then
        echo -e "\n$display_name のリンクを作成します."

        [ -e "$dist" ] && mkdir -p "$BACKUP_DIR/vscode/" && mv "$dist" "$BACKUP_DIR/vscode/settings.json" # バックアップ

        ln -sf "$src" "$dist"  # リンク作成
        echo "$display_name のリンクを作成しました."
    fi

    # asdf の 設定ファイル
    display_name="asdf > .tool-versions"
    src="$DOT_DIR/asdf/.tool-versions"
    dist="$HOME/.tool-versions"
    if is_setup "$display_name"; then
        echo -e "\n$display_name のリンクを作成します."

        [ -e "$dist" ] && mkdir -p "$BACKUP_DIR/asdf/" && mv "$dist" "$BACKUP_DIR/asdf/.tool-versions" # バックアップ

        ln -sf "$src" "$dist"  # リンク作成
        echo "$display_name のリンクを作成しました."
    fi

    echo -e "\ndotfiles のリンクを作成しました."
# }}} dotfiles のリンク作成 ここまで

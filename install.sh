#!/bin/bash
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
    # Usage: error $summary $discription
    error() {
        echo -e "\nERROR: $1\n"
        echo -e $2
        exit 1
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
        error "dotfiles already exists!" "you should backup \"\$HOME/dotfiles\" and execute delete command \"rm -rf \$HOME/dotfiles\""
    fi
# }}} dotfiles のダウンロード ここまで

# dotfile のリンク作成 ここから {{{
    echo -e "\ndotfiles のリンクを作成します."
    for file in .zshrc; do
        if is_setup "$file"; then
            echo -e "\n$file のリンクを作成します."

            [ -e $HOME/$file ] && mv "$HOME/$file" "$BACKUP_DIR/$file" # バックアップ

            ln -sf "$DOT_DIR/$file" "$HOME/$file" # リンク作成
            echo "$file のリンクを作成しました."
        fi
    done
    echo -e "\ndotfiles のリンクを作成しました."
# }}} dotfiles のリンク作成 ここまで

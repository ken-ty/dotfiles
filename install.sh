#!/bin/bash

# # 実行場所変更
# # cd `dirname $0` # このスクリプトが配置されているディレクトリに移動
# echo `dirname $0`
# # cd ../$FLUTTER_PROJECT_DIRECTORY # Flutter プロジェクトに移動

# 変数 ここから {{{
    DOT_DIR="$HOME/dotfiles" # dotfile を 格納するディレクトリ
    BACKUP_DIR="$HOME/dotfiles_backup" # backup を 格納するディレクトリ
# }}} 変数 ここまで

# コマンドが存在するかチェック
has() {
    type "$1" > /dev/null 2>&1
}

# エラー終了する
# 
# Usage: error $summary $discription
error() {
    echo -e "\nERROR: $1\n"
    echo -e $2
    exit 1
}



# バックアップファイルを作成する
echo "バックアップファイルを作成します."
if [ ! -d ${BACKUP_DIR} ]; then    
    mkdir $BACKUP_DIR
    echo "$BACKUP_DIR を作成しました."
else
    echo "$BACKUP_DIR は既に存在します."
fi
echo "バックアップは $BACKUP_DIR に格納されます."

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

echo -e "\ndotfiles のリンクを作成します."
for file in .zshrc; do
    
    echo -e "\n$file のリンクを作成します."

    [ -e $HOME/$file ] && mv "$HOME/$file" "$BACKUP_DIR/$file" # バックアップ

    ln -sf "$DOT_DIR/$file" "$HOME/$file" # リンク作成
    echo "$file のリンクを作成しました."
done
echo -e "\ndotfiles のリンクを作成しました."

# .zshrc の再読み込み
source "$HOME/.zshrc"

# githubからソースコードを落とす
# 参考は(こちら)[https://docs.github.com/ja/repositories/working-with-files/using-files/downloading-source-code-archives]

# echo "install.sh を実行しました! この shell はまだ何もしません!"
# echo "既存の .zshrc バックアップして, dotfiles/.zshrc のシンボリックリンクを作成します."
# mkdir -p $HOME/backup && mv $HOME/.zshrc $HOME/backup/.zshrc # バックアップ
# ln -s $(pwd)/.zshrc $HOME/.zshrc # シンボリックリンク
# source ~/.zshrc # 再読み込み


# dotfiles

TODO: ここに 概要 を記載する.

## Usage

以下を実行する

```
bash -c "$( curl -fsSL https://raw.github.com/ken-ty/dotfiles/master/install.sh )"
```

TODO: 各ファイルの機能や使用方法についてのドキュメントも作成する.

## 登録方法

```
mkdir ~/backup &&  mv ~/.zshrc ~/backup/.zshrc # バックアップ
ln -s $(pwd)/.zshrc $HOME/.zshrc # シンボリックリンク
source ~/.zshrc # 再読み込み
```

## 貢献方法

fork して開発し, PR 経由でマージします. 
マージ前に, ローカルで最新のmasterを取り込んで rebase してください.

issue 単位で作業してほしいです. issue が大きい場合, より小さな task へと分割します.
分割方法などは 検討中です.

TODO: 貢献方法 の検証を行う.

## ライセンス

このリポジトリの ドキュメンテーション (.md 拡張子の全てのファイル) は CC-BY ライセンスの下でライセンスされます。
このリポジトリのすべてのその他のコードは MIT ライセンスの下でライセンスされています。

## 謝辞

このリポジトリへの貢献や努力をしていただきありがとうございます。
marge されるかどうかに関わらず, その貢献はこのリポジトリをよりよくするでしょう！
私たちはあなたに大変感謝します！!
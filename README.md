# dotfiles

$HOME 配下に格納される 設定ファイル群 の git 管理。
シェルやエディタの設定からアプリケーションの設定など。

他、環境構築に使える script もここで管理する。

## 管理しているもの

| ファイル名 | 説明 |
| --- | --- |
| .zshrc | zsh の設定 |
| .gitconfig | git の設定 |
| vscode/settings.json | vscode の User 設定 |



## Usage

以下を実行する

```
bash -c "$( curl -fsSL https://raw.github.com/ken-ty/dotfiles/master/install.sh )"
```

TODO: 各ファイルの機能や使用方法についてのドキュメントも作成する。

## 登録方法

```
source $HOME/.zshrc # zshrc の再読み込み
```

## 貢献方法

./CONTRIBUTING.md を確認ください。


## ライセンス

このリポジトリの ドキュメンテーション (.md 拡張子の全てのファイル) は CC-BY ライセンスの下でライセンスされます。
このリポジトリのすべてのその他のコードは MIT ライセンスの下でライセンスされています。


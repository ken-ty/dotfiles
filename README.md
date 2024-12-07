# dotfiles

$HOME 配下に格納される設定ファイル群を git で管理するリポジトリです。  
シェルやエディタの設定から、アプリケーション設定、環境構築用スクリプトまでを一元管理します。

---

## 管理しているもの

| ファイル名              | 説明                                 |
| ----------------------- | ------------------------------------ |
| `.zshrc`               | zsh の設定                          |
| `.gitconfig`           | git の設定                          |
| `vscode/settings.json` | VSCode の User 設定                 |
| `.tool-versions`       | asdf で管理している各ツールのグローバルバージョン |

---

## Usage

このリポジトリをクローンし、dotfiles をセットアップするには以下のコマンドを実行します：

```
bash -c "$(curl -fsSL https://raw.github.com/ken-ty/dotfiles/main/install.sh)"
```

### このコマンドが行う処理
1. `$HOME/dotfiles` ディレクトリにリポジトリをダウンロード。
2. 必要な設定ファイルのシンボリックリンクを作成。
3. 既存の設定ファイルを `$HOME/dotfiles_backup` にバックアップ。

> **注意:** `$HOME/dotfiles` がすでに存在する場合、削除してから再実行してください。  
> 以下のコマンドで削除可能です：  
> ```
> rm -rf $HOME/dotfiles
> ```

---

## インストール後の必要手順

インストール後、環境を有効にするために以下のコマンドを実行してください：

### 1. zshrc の再読み込み
```
source $HOME/.zshrc
```

### 2. VSCode の拡張機能インポート
必要に応じて、VSCode の拡張機能をインポートします：
```
source $HOME/dotfiles/vscode/my_vscode_extensions.sh
```

---

## TODO

- 各設定ファイルの具体的な役割や使用例についてのドキュメントを作成する：
  - `.zshrc`: カスタムエイリアスやプラグイン設定の解説
  - `.gitconfig`: コミット署名や便利な設定項目の紹介
  - `vscode/settings.json`: 推奨拡張機能と設定例
  - `.tool-versions`: asdf を用いたツール管理方法のサンプル

---

## 貢献方法

貢献いただける場合は、リポジトリ内の [`CONTRIBUTING.md`](./docs/CONTRIBUTING.md) をご確認ください。

---

## ライセンス

- このリポジトリのドキュメント（`.md` ファイルすべて）は [CC-BY ライセンス](https://creativecommons.org/licenses/by/4.0/) に基づきライセンスされています。
- その他のコードは [MIT ライセンス](https://opensource.org/licenses/MIT) に基づきライセンスされています。

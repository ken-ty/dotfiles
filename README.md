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
| `mcp/servers.json`     | Claude Code に繋ぐ MCP サーバの宣言   |

---

## MCP

Claude Code に繋ぐ MCP サーバを `mcp/servers.json` で宣言的に管理しています。
新しいマシンでは dotfiles を入れたあとに一度流します。

```bash
bash mcp/install.sh
```

繋がらないものがあるときは、宣言と実態のズレを見ます（読み取りのみ）。

```bash
bash mcp/doctor.sh
```

`claude.ai` のコネクタ（Notion / Gmail / Slack / …）は **OAuth トークンが実体なので
設定からは復元できません**。`install.sh` はチェックリストを出すだけで、認証は手動です。

詳細は [`mcp/README.md`](mcp/README.md)。

## Usage

このリポジトリをクローンし、dotfiles をセットアップするには以下のコマンドを実行します：

```bash
bash -c "$(curl -fsSL https://raw.github.com/ken-ty/dotfiles/main/install.sh)"
```

### Windows

`install.sh` は Mac / Ubuntu 専用（Git Bash から実行すると案内を出して止まる）。Windows は
**`install.ps1`** を使う。

```powershell
git clone git@github.com:ken-ty/dotfiles.git
powershell -ExecutionPolicy Bypass -File dotfiles\install.ps1
```

「git を入れる」から「Claude Code でスキルが有効になる」までを一本で通す:

1. winget で Git / GitHub CLI / ghq / Node.js / fzf
2. Discord（任意）
3. `core.sshCommand` を Windows OpenSSH に向ける ── **非 ASCII のユーザ名では必須**。
   これが無いと、鍵も登録も正しいのに `publickey` 拒否になる
4. ed25519 鍵の生成 → 公開鍵を表示 → 登録待ち → `ssh -T` で疎通確認
5. `gh auth status`（ログインはブラウザ対話なので手動）
6. agent-skills / agent-skills-store を clone して配線
7. `$PROFILE` に `windows/Microsoft.PowerShell_profile.ps1` を dot-source する 1 行を追記
8. PSFzf（任意。Ctrl+r の履歴 fuzzy search に要る）

**symlink の権限が無ければ、6 で失敗せずに打つべきコマンドを表示して飛ばす。**
開発者モードか sudo のどちらかを有効にして再実行すれば、そこだけ進む。

`install.sh` と違い**設定ファイルの symlink は張らない**（Windows は symlink に特権が要り、
`.zshrc` も使わないため）。共通化は後回しにしてある。
PowerShell profile だけは、`$PROFILE` に dot-source の 1 行を追記することで
symlink 相当の「リポジトリを直せば即反映」を得ている。既存の `$PROFILE` は上書きしない。

#### PowerShell の fzf 連携

`.zshrc` の fzf まわりと同じ操作感を Windows にも用意してある。

| キー | 動作 | 対応する `.zshrc` |
| --- | --- | --- |
| `Ctrl+]` | `ghq list -p` を fzf で絞り込んで移動 | `cd-ghq-list--fzf` |
| `Ctrl+r` | コマンド履歴を fzf で絞り込み | `fzf-select-history` |
| `g` | `Ctrl+]` と同じ（エイリアス） | — |

**`Ctrl+]` が届かないターミナル設定がある。** 反応しなければ `g` で運用するか、
profile の `-Chord` を書き換える。

profile に日本語コメントを書くなら **UTF-8 BOM 付きで保存する**。PowerShell 5.1 は
BOM 無しを CP932 として読むため、BOM を落とすとコメントが化けて構文エラーになる。

詰まりどころの詳細は `my-windows-setup` スキル
（[agent-skills-store](https://github.com/ken-ty/agent-skills-store)）にある。

### このコマンドが行う処理

1. `$HOME/dotfiles` ディレクトリにリポジトリをダウンロード。
2. 必要な設定ファイルのシンボリックリンクを作成。
3. 既存の設定ファイルを `$HOME/dotfiles_backup` にバックアップ。

> **`install.sh` は AI エージェントのスキルを扱いません。** 以前は `ai-skills` を clone して
> いましたが、そのリポジトリは保守されていないため落としました。スキルが要るなら
> [agent-skills](https://github.com/ken-ty/agent-skills) を別途入れてください。
> Windows の `install.ps1` は Step 6 でそこまで面倒を見ます（sh 側との共通化は未着手）。

> **注意:** `$HOME/dotfiles` がすでに存在する場合、削除してから再実行してください。  
> 以下のコマンドで削除可能です：  
>
> ```bash
> rm -rf $HOME/dotfiles
> ```

---

## インストール後の必要手順

インストール後、環境を有効にするために以下のコマンドを実行してください：

### 1. zshrc の再読み込み

```bash
source $HOME/.zshrc
```

### 2. gitconfig.local の作成

秘匿情報や個人によって異なる Git 設定は `git/.gitconfig.local` に記載します。
このファイルは `.gitignore` で追跡対象外にしているため、手動で作成してください。

```bash
touch $HOME/dotfiles/git/.gitconfig.local
```

必要に応じて、ユーザー名やメールアドレスなどを記載します：

```gitconfig
[user]
    name = Your Name
    email = your@email.com
```

### 3. VSCode の拡張機能インポート

必要に応じて、VSCode の拡張機能をインポートします：

```bash
source $HOME/dotfiles/vscode/my_vscode_extensions.sh
```

---

## CI

**このリポジトリに GitHub Actions のワークフローは無い。**

以前は `github-actions-demo.yml`（GitHub のチュートリアルそのままの、echo だけを
するデモ）が置いてあったが、**何も検証していないうえ `on: [push]` で全ブランチに
発火していた**ので消した。private リポジトリなので、走った分は無料枠 2,000 分を
そのまま食う。

検証したいものが出てきたら足してよい。そのときは
[cost-management のチェックリスト](https://github.com/ken-ty/cost-management/blob/main/github-actions/docs/workflow-checklist.md)
を上から見ること。特に **`timeout-minutes` と `concurrency` は必須**
（消したデモにはどちらも無く、既定の 360 分が効く形だった）。

経緯 → [ken-ty/cost-management#12](https://github.com/ken-ty/cost-management/issues/12)

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

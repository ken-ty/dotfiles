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
| `chunks/<名前>/Brewfile` | Homebrew で入れるものを技術のひと塊 (チャンク) ごとに分けたもの。「チャンク」の節 |
| `mcp/servers.json`     | Claude Code に繋ぐ MCP サーバの宣言   |
| `macos/defaults.sh`    | macOS のシステム設定 (defaults)。Spaces の並びなど |

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

## macOS のシステム設定

「システム設定」で手で触る項目のうち `defaults` で再現できるものを `macos/defaults.sh` に集めています。
`install.sh` から呼ばれますが、単独でも流せます (冪等)。

```bash
bash macos/defaults.sh
```

いま入っているのは Mission Control の「操作スペースを最近使った順に自動で並べ替える」をオフにする 1 件です。
これがオンだと、Cmd+Tab で別スペースのアプリへ飛ぶたびにスペースの並びが崩れます。

詳細は [`macos/README.md`](macos/README.md)。

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

1. winget で Git / GitHub CLI / ghq / Node.js
2. Discord（任意）
3. `core.sshCommand` を Windows OpenSSH に向ける ── **非 ASCII のユーザ名では必須**。
   これが無いと、鍵も登録も正しいのに `publickey` 拒否になる
4. ed25519 鍵の生成 → 公開鍵を表示 → 登録待ち → `ssh -T` で疎通確認
5. `gh auth status`（ログインはブラウザ対話なので手動）
6. agent-skills / agent-skills-store を clone して配線

**symlink の権限が無ければ、6 で失敗せずに打つべきコマンドを表示して飛ばす。**
開発者モードか sudo のどちらかを有効にして再実行すれば、そこだけ進む。

`install.sh` と違い**設定ファイルの symlink は張らない**（Windows は symlink に特権が要り、
`.zshrc` も使わないため）。共通化は後回しにしてある。

詰まりどころの詳細は `my-windows-setup` スキル
（[agent-skills-store](https://github.com/ken-ty/agent-skills-store)）にある。

### このコマンドが行う処理

1. `$HOME/dotfiles` にリポジトリを `git clone` (git が無ければ tarball)。**すでに git checkout があればそのまま使う** (ghq 配下への symlink でもよい)
2. 設定ファイルのシンボリックリンクを作成。既存のファイルは `$HOME/dotfiles_backup` に退避。すでに同じ場所を指していれば何もしない
3. Homebrew が無ければ入れ、**チャンク** (下記) を選んで `brew bundle`
4. macOS の `defaults` (任意)

何度実行しても同じ結果になります。`$HOME/dotfiles` が git checkout でないディレクトリのときだけ止まるので、
そのときは退避してから再実行してください。

```bash
bash install.sh                            # 対話。設定ファイルは 1 つずつ聞き、チャンクは 3 択
bash install.sh --mode recommended --yes   # 何も聞かない。サーバー向け
bash install.sh --mode full                # 全チャンク
bash install.sh --mode select              # チャンクを 1 つずつ選ぶ (推奨のものは既定 Y)
```

> **`install.sh` は AI エージェントのスキルを扱いません。** 以前は `ai-skills` を clone して
> いましたが、そのリポジトリは保守されていないため落としました。スキルが要るなら
> [agent-skills](https://github.com/ken-ty/agent-skills) を別途入れてください。
> Windows の `install.ps1` は Step 6 でそこまで面倒を見ます（sh 側との共通化は未着手）。

### チャンク

技術を 1 塊ごとに `chunks/<名前>/` に分けてあります。`Brewfile` (何を入れるか) と、任意の `install.sh`
(入れた後の 1 手。asdf のプラグインや fzf のキーバインドなど)。`Brewfile` 1 行目の `# desc:` が一覧に出ます。

| チャンク | 中身 | 推奨 |
| --- | --- | --- |
| `core` | git / gh / ghq / fzf / jq / tree / tig / bw。`.zshrc` が前提にしている。`install.sh` が `~/.fzf.zsh` を作る (指す先が消えていれば作り直す) | ✓ |
| `zsh` | zsh-autosuggestions / zsh-completions / zsh-git-prompt | ✓ |
| `node` | asdf と `.tool-versions` の nodejs | ✓ |
| `docker` | colima + docker CLI。**Docker Desktop が入っている機械では飛ばす** (`install.sh` が検出する) | |
| `flutter` | asdf の flutter、fvm、xcodes CLI、openjdk、bundletool。JDK は brew の openjdk 1 本 | |
| `media` | ffmpeg / graphviz / librsvg / webp / avif など | |
| `langs` | php / python / rbenv / yarn / chezmoi | |
| `gui` | vagrant / virtualbox (cask) | |
| `vscode` | VSCode の拡張機能。`code` コマンドが要る | |

推奨 (`--mode recommended`) は `chunks/recommended` に列挙したもの。サーバーには推奨だけ入れ、
開発機は full か select で足します。チャンクを足すときはディレクトリを 1 つ作るだけで一覧に出ます。

---

## インストール後の必要手順

インストール後、環境を有効にするために以下のコマンドを実行してください：

### 1. zshrc の再読み込み

```bash
source $HOME/.zshrc
```

### 2. gitconfig.local

秘匿情報や機械ごとに違う Git 設定 (`gh auth setup-git` が書く credential helper など) は
`git/.gitconfig.local` に書きます。`.gitignore` で追跡対象外です。

`install.sh` が空のファイルを作って `~/.gitconfig.local` に symlink します。
`.gitconfig` の `include.path = .gitconfig.local` は **`~/.gitconfig` からの相対で解決され、
symlink を辿らない** ので、`git/.gitconfig.local` に書いただけでは読まれません
(2026-09-14 に mini で実測。MBP も同じ状態で、読まれていなかった)。

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

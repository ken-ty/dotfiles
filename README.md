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

1. `$HOME/dotfiles` ディレクトリにリポジトリをダウンロード。
2. 必要な設定ファイルのシンボリックリンクを作成。
3. 既存の設定ファイルを `$HOME/dotfiles_backup` にバックアップ。
4. ai-skills リポジトリの clone（任意、対話式で URL を指定可能）。

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

### 3. ai-skills のセットアップ (任意)

`install.sh` の実行中に ai-skills のセットアップを選択すると、リポジトリ URL の入力を求められます。
デフォルトは `git@github.com:ken-ty/ai-skills.git` (private) で、Enter だけで進めます。
別のリポジトリを使いたい場合は URL を入力してください。

clone 後、スキルを各 AI エージェントにリンクするには以下を実行します：

```bash
$HOME/dotfiles/ai-skills/setup.sh
```

`install.sh` でスキップした場合は、後から手動で clone できます：

```bash
git clone <your-ai-skills-repo-url> $HOME/dotfiles/ai-skills
```

`ai-skills/` は `.gitignore` で追跡対象外のため、各自のリポジトリを自由に使えます。

### 4. VSCode の拡張機能インポート

必要に応じて、VSCode の拡張機能をインポートします：

```bash
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

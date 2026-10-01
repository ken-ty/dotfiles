# dotfiles

$HOME 配下に格納される設定ファイル群を git で管理するリポジトリです。  
シェルやエディタの設定から、アプリケーション設定、環境構築用スクリプトまでを一元管理します。

**OS ごとの説明はそれぞれの README に分けてあります。** この README には OS を問わない
ことだけを書きます。

| OS | 入口 | 説明 |
| --- | --- | --- |
| macOS (と Ubuntu) | `install.sh` | [`macos/README.md`](macos/README.md) |
| Windows | `windows/install.ps1` | [`windows/README.md`](windows/README.md) |

このリポジトリが何を目指しているかは [`docs/VISION.md`](docs/VISION.md)、どう育ってきたかは
[`docs/HISTORY.md`](docs/HISTORY.md)、形を決めた判断は [`docs/adr/`](docs/adr/README.md) にあります。

---

## 構成

OS 固有のものは `macos/` と `windows/` に置き、それ以外 (直下) は OS を問わず使うものです。

| 置き場所 | 対象 | 中身 |
| --- | --- | --- |
| `macos/` | macOS | Homebrew のチャンク (`chunks/`)、システム設定 (`defaults.sh`) |
| `windows/` | Windows | ブートストラップ (`install.ps1`)、PowerShell の profile |
| `git/` | 共通 | git の設定 |
| `vscode/` | 共通 | VSCode の User 設定と拡張機能の一覧 |
| `mcp/` | 共通 | Claude Code に繋ぐ MCP サーバの宣言 |
| `install.sh` `.zshrc` `zsh/` `asdf/` | macOS / Ubuntu | 直下に残している理由は [`macos/README.md`](macos/README.md) の冒頭 |

**新しく足すときは、まずどの OS で使うかを決めて置き場所を選ぶ。** 片方の OS でしか
使わないものを直下に置かない。説明もその OS の README に書く。

---

## Git

`git/.gitconfig` が共通の設定です。機械ごとに違うもの (credential helper など) は
`git/.gitconfig.local` に書きます (`.gitignore` で追跡対象外)。張り方は OS ごとに違うので、
それぞれの README を見てください。

`git/ignore` はグローバル gitignore で、全リポジトリで無視するもの
(`.claude/settings.local.json`、`CLAUDE.local.md`) を書きます。git が既定で読む
`~/.config/git/ignore` に `install.sh` が symlink するので、`.gitconfig` に
`core.excludesfile` は書きません。Windows の `install.ps1` はまだ張りません。

### コミットのメールは GitHub の noreply にする

コミットの作者メールは、push した時点で誰でも読めます。public なリポジトリに一度載ると
履歴を書き換えない限り消せないので、**最初から GitHub の noreply
(`<id>+<login>@users.noreply.github.com`) でコミットします。**

`install.sh` は `git/noreply-email.sh` を呼び、`gh api user` で引いた id と login から
noreply を組み立てて `~/.gitconfig.local` の `user.email` に書きます (`user.name` が無ければ
login も)。値はこのリポジトリに書かないので、fork した人が流せばその人の noreply が入ります。
Windows の `install.ps1` は Step 5 で同じことを `git config --global` に対して行います。

- **既に noreply 以外の `user.email` が入っていれば書き換えません。** 表示して止まるだけです
- gh にログインしていなければ何もしません。`gh auth login` のあと、もう一度流します:
  `bash ~/dotfiles/git/noreply-email.sh`
- 何度流しても同じ結果です

GitHub 側の設定は手で入れます (スクリプトからは触りません)。Settings → Emails で:

- **Keep my email addresses private** — Web 上の操作 (マージなど) のコミットも noreply になる
- **Block command line pushes that expose my email** — 個人のメールが載ったコミットの push を GitHub が拒む

**先方に指定されたメールでコミットする仕事は、そのリポジトリの中だけで上書きします。**
グローバルは noreply のままにしておきます。

```bash
git -C <そのリポジトリ> config user.email <指定のメール>
```

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

---

## CI

**このリポジトリに GitHub Actions のワークフローは無い。**

以前は `github-actions-demo.yml`（GitHub のチュートリアルそのままの、echo だけを
するデモ）が置いてあったが、**何も検証していないうえ `on: [push]` で全ブランチに
発火していた**ので消した。当時は private リポジトリだったので、走った分が無料枠
2,000 分をそのまま食っていた。

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

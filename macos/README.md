# macos

macOS のセットアップ。入口はリポジトリ直下の **`install.sh`**。

```bash
bash -c "$(curl -fsSL https://raw.github.com/ken-ty/dotfiles/main/install.sh)"
```

`install.sh` は Ubuntu でも動くが、Homebrew を入れるのは Mac だけなので、Ubuntu では
設定ファイルの symlink までで止まる (チャンクは入らない)。Windows は
[`windows/README.md`](../windows/README.md)。

`install.sh`・`.zshrc`・`zsh/` は macOS 専用に近いが、**リポジトリ直下に置いたまま**に
している。`install.sh` は上の curl の URL が、`.zshrc` は各マシンの `~/.zshrc` の symlink が
その場所を指しているので、動かすと既存のマシンが壊れる。

## 管理しているもの

| ファイル名 | 説明 |
| --- | --- |
| `../install.sh` | Mac / Ubuntu のブートストラップ。「install.sh が行う処理」の節 |
| `../.zshrc` | zsh の設定 |
| `../zsh/keybindings.conf` | zsh のキーバインドの表。「キーバインド」の節 |
| `../zsh/widgets/*.zsh` | キーバインドから呼ぶ zle ウィジェット。1 関数 1 ファイル |
| `../zsh/starship.toml` | プロンプト (starship) の定義。「プロンプト」の節 |
| `../asdf/.tool-versions` | asdf で管理している各ツールのグローバルバージョン |
| `chunks/<名前>/Brewfile` | Homebrew で入れるものを技術のひと塊 (チャンク) ごとに分けたもの。「チャンク」の節 |
| `defaults.sh` | macOS のシステム設定 (defaults)。「システム設定」の節 |

## install.sh が行う処理

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

## チャンク

技術を 1 塊ごとに `macos/chunks/<名前>/` に分けてあります。`Brewfile` (何を入れるか) と、任意の `install.sh`
(入れた後の 1 手。asdf のプラグインや fzf のキーバインドなど)。`Brewfile` 1 行目の `# desc:` が一覧に出ます。

| チャンク | 中身 | 推奨 |
| --- | --- | --- |
| `core` | git / gh / ghq / fzf / jq / tree / tig / bw。`.zshrc` が前提にしている。`install.sh` が `~/.fzf.zsh` を作る (指す先が消えていれば作り直す) | ✓ |
| `zsh` | zsh-autosuggestions / zsh-completions / starship。`.zshrc` が読む (starship は `zsh/starship.toml` を指して init)。`install.sh` が compaudit を通す | ✓ |
| `node` | asdf と `.tool-versions` の nodejs | ✓ |
| `docker` | colima + docker CLI。**Docker Desktop が入っている機械では飛ばす** (`install.sh` が検出する) | |
| `flutter` | asdf の flutter、xcodes CLI、openjdk、bundletool、Android Studio。JDK は brew の openjdk 1 本 | |
| `media` | ffmpeg / graphviz / librsvg / webp / avif など | |
| `langs` | php / python / rbenv / yarn / chezmoi / .NET SDK | |
| `gui` | 日常の GUI アプリ (Chrome / Slack / Discord / Notion / Spotify / Claude / Arq / Adobe CC / Rectangle / Stats / Ice …) | |
| `devtools` | 開発向けの GUI と SDK (vagrant / virtualbox / Postman / ngrok / tuist / XQuartz / codex) | |
| `mas` | App Store のアプリ (`mas`)。Bitwarden / LINE / Excel / Kindle / Brother の印刷系など | |
| `vscode` | VSCode 本体 (cask) と拡張機能 | |

推奨 (`--mode recommended`) は `macos/chunks/recommended` に列挙したもの。サーバーには推奨だけ入れ、
開発機は full か select で足します。チャンクを足すときはディレクトリを 1 つ作るだけで一覧に出ます。

## インストール後の必要手順

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

## キーバインド

zsh のキーバインドは `.zshrc` に直書きせず、`zsh/keybindings.conf` の表で持つ。
1 行 1 バインド、`空白区切り + # コメント`（fstab と同じ書式）。zsh の `read` で
読めるので jq も yq も要らない。

```
# key    widget               state  説明
^]       cd-ghq-list--fzf     on     ghq のリポジトリを fzf で選んで cd
^R       fzf-history-widget   on     fzf 付属: 履歴を fzf で検索
^T       fzf-file-widget      on     fzf 付属: ファイルを選んで挿入
```

fzf 付属のバインド（`^T` `^R` `Alt+C` `Tab`）も同じ表に載せてあるので、そこで
`off` にすれば外れる。widget の実体は `zsh/widgets/<name>.zsh`（dotfiles 自前）か
`fzf --zsh`（fzf 付属）。

| やりたいこと | 手 |
| --- | --- |
| 一覧を見る | `keybind list` — 表と、実際に `bindkey` されているか（`bound` / `no-widget`）を並べて出す |
| この機械だけ切る / 入れる | `keybind off '^T'` / `keybind on '^T'` — 即反映して `~/.zsh-keybindings.local` に書く（git 管理外） |
| 全機械で変える | `keybind edit` → `keybindings.conf` を直す → commit |
| キーを変える | 表の 1 列目を書き換える |

`~/.zsh-keybindings.local` は `keybindings.conf` より後に読まれる（後勝ち）ので、
「リポジトリでは on、この機械では off」が成り立つ。

Windows の PowerShell に同じ操作感を用意したものは [`windows/README.md`](../windows/README.md) にある。

## プロンプト

プロンプトの見た目は `.zshrc` に書かず、[starship](https://starship.rs/) に任せて
`zsh/starship.toml` で持つ。`.zshrc` が `STARSHIP_CONFIG` でこのファイルを指して
`starship init zsh` を呼ぶので、`~/.config/starship.toml` は作らない。starship が
入っていない機械では何もせず、macOS 既定の `user@host dir %` のまま。

土台は公式プリセットの [Jetpack](https://starship.rs/presets/jetpack) で、左に `◎`、右に
ディレクトリ・git・そのリポジトリで使うツール・時刻が出る 2 段の形。プリセットから変えた
箇所は `zsh/starship.toml` の `# jetpack:` コメントに理由がある (sudo と gcloud を切る、
dart / nodejs を asdf の `.tool-versions` を読む custom に置き換える、main を隠さない、など)。

```
                                                                        ▴167▿34
◄ 4s ◎                    □ dotfiles △ feat/starship-modules:main⎪●◦◃◈⎥ 17:33
```

上の行は作業ツリーの差分行数 (あるときだけ)。下の行の左は直前のコマンドの所要時間 (2 秒以上)
と `◎` (失敗すると `○`)、右は `ディレクトリ △ ブランチ⎪状態⎥` に続いて、pubspec.yaml が
あれば `flutter ◁◅ 3.47.0`、package.json があれば `node ◫ 24.15.0`、Dockerfile があれば
`docker ◧ colima`。状態の記号は `▴│n│` ahead `▿│n│` behind `▪┤n│` staged `●◦` modified
`◌◦` untracked `◃◈` stashed `◪◦` conflicted。ssh 先ではホスト名・IP・ユーザーが左に足される。

**Nerd Font は要らないが、フォントは JetBrains Mono にする。** Jetpack の記号は Unicode の
幾何記号で、Monaco はそのうち 46 個を持たない (他のフォントに逐次フォールバックして幅が
ずれ、右プロンプトが崩れる)。JetBrains Mono は全部持つ。フォント自体は `macos/chunks/gui` で
入る。Terminal.app の切り替えは 1 コマンド:

```sh
osascript -e 'tell application "Terminal" to set font name of settings set "Pro" to "JetBrainsMono-Regular"'
```

("Pro" は使っているプロファイル名。`defaults read com.apple.Terminal "Default Window Settings"`
で分かる。画面でやるなら Terminal → 設定 → プロファイル → 左の一覧で Pro → テキストタブの
フォント「変更...」)

| やりたいこと | 手 |
| --- | --- |
| 出すものを増やす / 減らす | `zsh/starship.toml` の `format` (左) / `right_format` (右) に `$cmd_duration` などを足す・消す。モジュール一覧は https://starship.rs/config/ |
| 表示を確かめる | `starship prompt` (左) と `starship prompt --right` (右)。`--status 1` で失敗時の色 |
| 遅くなっていないか | `starship timings` — モジュールごとの所要時間。足したものが 50ms を超えたら切るか custom で軽くする |
| 設定の間違いを探す | `starship config` はエディタで開くだけ。`starship explain` が各モジュールの中身を出す |

## システム設定 (defaults)

「システム設定」で手で触る項目のうち、`defaults` コマンドで再現できるものを `defaults.sh` に
集めています。`install.sh` から呼ばれますが、単独でも流せます (冪等)。

```bash
bash macos/defaults.sh
```

書き込まずに差分だけ見るとき:

```bash
bash macos/defaults.sh --check
```

### 何を管理しているか

| 設定 | 値 | 理由 |
| --- | --- | --- |
| Mission Control: 最新の使用状況に基づいて操作スペースを自動的に並べ替える | オフ | オンだと Cmd+Tab で別スペースのアプリに飛んだだけでスペースの並びが変わり、「何番目に何を置いたか」で管理できなくなる |

### 項目を足すとき

`defaults.sh` の `SETTINGS` 配列に 1 行足します。書式は `domain|key|type|value|説明`。

どのキーか分からないときは、変更前後の全 defaults を取って差分を見るのが早いです。

```bash
defaults read > /tmp/before.plist
# システム設定で手で切り替える
defaults read > /tmp/after.plist
diff /tmp/before.plist /tmp/after.plist
```

### ここで管理しないもの

- **スペースへのアプリの割り当て** (Dock のアイコン右クリック > オプション > 割り当て先)。
  `com.apple.spaces` に UUID 付きで書かれ、マシンをまたいで再現できないので手で設定します。
- **Ctrl+数字 で操作スペースへ直接移動** (キーボード > キーボードショートカット > Mission Control)。
  `com.apple.symbolichotkeys` に書かれますが構造が壊れやすいので、手で有効にします。

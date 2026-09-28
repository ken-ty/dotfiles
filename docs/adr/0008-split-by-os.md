# 0008. README とコードを 共通 / macOS / Windows に分ける

- 状態: 採用
- 時期: 2026-09-23
- 関連: [#75](https://github.com/ken-ty/dotfiles/pull/75)

## 背景

Windows の `install.ps1` が入り、README に macOS と Windows の説明が混ざった。

## 決定

- OS 固有のものは `macos/` と `windows/`。直下は OS を問わないものだけ。説明もその OS の README に書く
- ただし `install.sh`・`.zshrc`・`zsh/`・`asdf/` は直下に残す。curl で取る URL と、各機械の `~/.zshrc` の symlink がその場所を指しているので、動かすと既存の機械が壊れる

## 結果

- 新しく足すときは、まずどの OS で使うかを決めて置き場所を選ぶ

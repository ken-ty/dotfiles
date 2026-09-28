# 0006. 設定は表で持ち、機械ごとの差は `.local` で後勝ちにする

- 状態: 採用
- 時期: 2026-09-15
- 関連: [#65](https://github.com/ken-ty/dotfiles/pull/65)

## 背景

`.zshrc` にキーバインドが直書きで、fzf 付属のバインドは切れなかった。「リポジトリでは on、この機械だけ off」を表せなかった。

## 決定

- キーバインドは fstab 型の表 `zsh/keybindings.conf` (key / widget / on|off / 説明)。zsh の `read` で読めるので依存なし
- 機械ごとの上書きは `~/.zsh-keybindings.local` (git 管理外) に書き、後から読んで勝たせる。`.gitconfig.local`、`.zshrc.local` も同じ考え方

## 結果

- `keybind list / on / off / edit` で表と実際の `bindkey` を突き合わせられる
- プロンプト (ADR 0007) も同じく 1 ファイルに寄せた

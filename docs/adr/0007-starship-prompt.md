# 0007. プロンプトは starship に任せ、Nerd Font なしで JetBrains Mono

- 状態: 採用
- 時期: 2026-09-17 〜 18
- 関連: [#69](https://github.com/ken-ty/dotfiles/pull/69) [#71](https://github.com/ken-ty/dotfiles/pull/71)

## 背景

プロンプトの定義は 2023-07 の `.zshrc` 刷新で消えていて、macOS 既定のまま出ていた。使われない `zsh-git-prompt` だけが Brewfile に残っていた。

## 決定

- 見た目は `zsh/starship.toml` の 1 ファイルで持ち、`.zshrc` からは `STARSHIP_CONFIG` で指すだけ
- 公式プリセット Jetpack を土台に、遅いモジュール (sudo、shim 経由の dart / node) を外すか `.tool-versions` を読む custom に置き換える
- Jetpack の記号は Unicode の幾何記号なので Nerd Font は要らない。Monaco は 46 個欠けるので JetBrains Mono にする

## 結果

- starship が無い機械では何もせず、既定のプロンプトのまま
- 変えた箇所の理由は toml の `# jetpack:` コメントに残す

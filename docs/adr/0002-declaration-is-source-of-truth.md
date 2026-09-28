# 0002. 宣言が正。install は冪等、ずれは読み取りだけで見つける

- 状態: 採用
- 時期: 2026-08 〜 09
- 関連: [#52](https://github.com/ken-ty/dotfiles/pull/52) [#55](https://github.com/ken-ty/dotfiles/pull/55) [#57](https://github.com/ken-ty/dotfiles/pull/57) [#65](https://github.com/ken-ty/dotfiles/pull/65)

## 背景

新しい機械のたびに、入れるべきもの・繋ぐべき MCP サーバを思い出しながら手で入れていた。手で直した設定は、どの機械にも戻らなかった。

## 決定

- 状態は宣言ファイルに書く: Brewfile のチャンク、`mcp/servers.json`、`macos/defaults.sh` の `SETTINGS`、`zsh/keybindings.conf`
- 適用するスクリプトは冪等にする (同じ先を指す symlink には触らない、差分があるものだけ書く)
- ずれを報告する読み取り専用の経路を必ず用意する (`mcp/doctor.sh`、`defaults.sh --check`、`keybind list`)

## 結果

- 手で変えたら宣言に戻すまでが作業になる
- OAuth が実体の claude.ai コネクタのように宣言から復元できないものは、自動配線せずチェックリストに留める

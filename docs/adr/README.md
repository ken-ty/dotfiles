# ADR (Architecture Decision Records)

このリポジトリの形を決めた判断の記録。1 判断 1 ファイル。経緯の全体は [HISTORY](../HISTORY.md)。

| # | 判断 |
| --- | --- |
| [0001](0001-no-secrets-in-repo.md) | 秘密はリポジトリに入れない |
| [0002](0002-declaration-is-source-of-truth.md) | 宣言が正。install は冪等、ずれは読み取りだけで見つける |
| [0003](0003-brew-chunks.md) | Homebrew を技術ごとのチャンクに分け、推奨 / full / select で選ぶ |
| [0004](0004-colima-instead-of-docker-desktop.md) | Docker Desktop をやめて colima にする |
| [0005](0005-drop-ai-skills.md) | AI スキルのセットアップを dotfiles から外す |
| [0006](0006-tables-and-local-overrides.md) | 設定は表で持ち、機械ごとの差は `.local` で後勝ちにする |
| [0007](0007-starship-prompt.md) | プロンプトは starship に任せ、Nerd Font なしで JetBrains Mono |
| [0008](0008-split-by-os.md) | README とコードを 共通 / macOS / Windows に分ける |
| [0009](0009-arq-exclusions.md) | Arq の除外は「/Users 丸ごと − フルパスの除外」で持つ |
| [0010](0010-squash-history-before-public.md) | 公開の前に履歴を「最初の commit + 公開時点」の 2 つにまとめる |

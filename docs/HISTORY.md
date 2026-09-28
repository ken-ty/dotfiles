# History

このリポジトリは 2026-09-28 に public にした。そのとき commit 履歴を **最初の commit (2023-04-16) と、公開時点の 1 commit** の 2 つにまとめた ([ADR 0010](adr/0010-squash-history-before-public.md))。
途中の経緯はここと [ADR](adr/) に残す。PR の番号は GitHub 上に残っているので、詳細は各 PR を見ればよい。

## 2023-04 — 始まり

- README だけの first commit (2023-04-16)。ChatGPT に出させたロードマップを Issue #1〜#6 に切った (dotfiles の作成 → 配置 → install スクリプト → ドキュメント → テスト → 公開)
- ライセンスを CC BY 4.0 に。貢献ガイド、GitHub Actions のデモ workflow ([#8](https://github.com/ken-ty/dotfiles/pull/8) [#9](https://github.com/ken-ty/dotfiles/pull/9))
- 空の `install.sh` と、`.gitconfig` のエイリアスを「メモするくらいのノリ」で置き始める ([#7](https://github.com/ken-ty/dotfiles/pull/7) [#10](https://github.com/ken-ty/dotfiles/pull/10))

## 2023-07 〜 2023-11 — 手元の設定を集める

- `.zshrc` を管理下に。既定のエディタを vim に ([#12](https://github.com/ken-ty/dotfiles/pull/12) [#14](https://github.com/ken-ty/dotfiles/pull/14))
- `install.sh` が symlink を張る前に確認するように。既存ファイルは `dotfiles_backup` へ退避 ([#15](https://github.com/ken-ty/dotfiles/pull/15))
- VS Code の User 設定と、Flutter (fvm) 向けの設定 ([#21](https://github.com/ken-ty/dotfiles/pull/21)〜[#29](https://github.com/ken-ty/dotfiles/pull/29))
- PR テンプレート、Fig の統合 ([#30](https://github.com/ken-ty/dotfiles/pull/30) [#31](https://github.com/ken-ty/dotfiles/pull/31))

## 2023-12 〜 2024-03 — Flutter 開発機として

- asdf の flutter プラグインの環境変数、pub でグローバルに入れたコマンドの PATH、`.tool-versions` の管理 ([#32](https://github.com/ken-ty/dotfiles/pull/32)〜[#37](https://github.com/ken-ty/dotfiles/pull/37))
- OS を判定して VS Code の設定の置き場所を変える。拡張機能の一覧を管理する ([#39](https://github.com/ken-ty/dotfiles/pull/39) [#40](https://github.com/ken-ty/dotfiles/pull/40))
- CodeRabbit によるレビューを入れていた時期 ([#39](https://github.com/ken-ty/dotfiles/pull/39)〜[#46](https://github.com/ken-ty/dotfiles/pull/46))

## 2024-04 〜 2025-07 — 散発的な更新

- ChatGPT で install.sh をリファクタ、asdf 0.18 への追従、Brewfile を 1 枚追加

## 2026-03 — 秘密を追い出す

- 秘匿情報を置く `git/.gitconfig.local` を追跡対象から外し、`.gitignore` へ ([#47](https://github.com/ken-ty/dotfiles/pull/47) [#48](https://github.com/ken-ty/dotfiles/pull/48)) → [ADR 0001](adr/0001-no-secrets-in-repo.md)
- AI スキル (ai-skills) を submodule で入れ、すぐに対話式 clone に変える ([#49](https://github.com/ken-ty/dotfiles/pull/49))

## 2026-08 — Windows と MCP

- Windows 11 を素の状態から立ち上げた手順を `install.ps1` 1 本にする ([#50](https://github.com/ken-ty/dotfiles/pull/50))
- Claude Code に繋ぐ MCP サーバを `mcp/servers.json` で宣言し、`install.sh` で配線、`doctor.sh` でずれを見る ([#52](https://github.com/ken-ty/dotfiles/pull/52)) → [ADR 0002](adr/0002-declaration-is-source-of-truth.md)
- 何も検証していないデモ workflow を消す ([#53](https://github.com/ken-ty/dotfiles/pull/53))
- 保守していない ai-skills のセットアップを落とす ([#54](https://github.com/ken-ty/dotfiles/pull/54)) → [ADR 0005](adr/0005-drop-ai-skills.md)

## 2026-09 — 宣言で持つ形に作り直す

- macOS の `defaults` を `macos/defaults.sh` に集める ([#55](https://github.com/ken-ty/dotfiles/pull/55))
- Docker Desktop をやめて colima に ([#56](https://github.com/ken-ty/dotfiles/pull/56)) → [ADR 0004](adr/0004-colima-instead-of-docker-desktop.md)
- Brewfile を技術ごとのチャンクに分け、推奨 / full / select で選べるように ([#57](https://github.com/ken-ty/dotfiles/pull/57)) → [ADR 0003](adr/0003-brew-chunks.md)
- MBP の実機と突き合わせる棚卸し。未コミットの変更の取り込み、使っていないものの削除、GUI アプリの宣言 ([#58](https://github.com/ken-ty/dotfiles/pull/58)〜[#62](https://github.com/ken-ty/dotfiles/pull/62) [#66](https://github.com/ken-ty/dotfiles/pull/66) [#67](https://github.com/ken-ty/dotfiles/pull/67))
- zsh の補完を実際に効かせる。キーバインドを表で持つ ([#63](https://github.com/ken-ty/dotfiles/pull/63) [#65](https://github.com/ken-ty/dotfiles/pull/65)) → [ADR 0006](adr/0006-tables-and-local-overrides.md)
- プロンプトを starship に任せ、Jetpack プリセットを土台に作り込む ([#69](https://github.com/ken-ty/dotfiles/pull/69) [#71](https://github.com/ken-ty/dotfiles/pull/71)) → [ADR 0007](adr/0007-starship-prompt.md)
- グローバル gitignore、Notion CLI、PowerShell の文字コードと ExecutionPolicy ([#68](https://github.com/ken-ty/dotfiles/pull/68) [#72](https://github.com/ken-ty/dotfiles/pull/72) [#73](https://github.com/ken-ty/dotfiles/pull/73) [#76](https://github.com/ken-ty/dotfiles/pull/76))
- README とコードを 共通 / macOS / Windows に分ける ([#75](https://github.com/ken-ty/dotfiles/pull/75)) → [ADR 0008](adr/0008-split-by-os.md)
- Arq の除外ルールを JSON で持つ ([#77](https://github.com/ken-ty/dotfiles/pull/77)) → [ADR 0009](adr/0009-arq-exclusions.md)
- **2026-09-28: public にする。** 履歴を 2 commit にまとめ、この文書と Vision / ADR を置く → [ADR 0010](adr/0010-squash-history-before-public.md)

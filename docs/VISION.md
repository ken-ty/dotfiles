# Vision

**新しい機械を 1 コマンドで「いつもの環境」にし、その後も手元と宣言がずれていないことを確かめられる状態を保つ。**

dotfiles は設定ファイルの置き場ではなく、「この機械に何が入っていて、どう配線されているか」の正本として扱う。
設定を手で直したら、それを宣言に戻すところまでが作業。

## 守っていること

| 原則 | 具体 | 決めた経緯 |
| --- | --- | --- |
| 宣言が正、実態は宣言から作る | Brewfile のチャンク、`mcp/servers.json`、`macos/defaults.sh`、`zsh/keybindings.conf`、`macos/arq/users.json` | [ADR 0002](adr/0002-declaration-is-source-of-truth.md) |
| 何度流しても同じ結果 (冪等) | `install.sh` は同じ先を指す symlink に触らない。`defaults.sh` は差分があるものだけ書く | [ADR 0002](adr/0002-declaration-is-source-of-truth.md) |
| ずれは読み取りだけで見つけられる | `mcp/doctor.sh`、`defaults.sh --check`、`keybind list` | [ADR 0002](adr/0002-declaration-is-source-of-truth.md) |
| 秘密はリポジトリに入れない | 名前だけ宣言し、値は Keychain / Bitwarden から実行時に取る。機械ごとの値は `*.local` (git 管理外) | [ADR 0001](adr/0001-no-secrets-in-repo.md) |
| 機械ごとの差は `.local` で後勝ち | `~/.gitconfig.local`、`~/.zsh-keybindings.local`、`~/.zshrc.local` | [ADR 0006](adr/0006-tables-and-local-overrides.md) |
| 入れるものは選べる | 推奨 / full / select。サーバーには推奨だけ | [ADR 0003](adr/0003-brew-chunks.md) |
| OS ごとに分ける | `macos/` と `windows/`。直下は OS を問わないものだけ | [ADR 0008](adr/0008-split-by-os.md) |
| 使っていないものは宣言から外す | 実機と突き合わせて、消したもの・終わったものを消す | [HISTORY](HISTORY.md) の 2026-09 |

## やらないこと

- **OAuth が実体のものを自動配線するふり。** claude.ai のコネクタなどは、チェックリストを出すところまで ([#52](https://github.com/ken-ty/dotfiles/pull/52))
- **AI エージェントのスキル管理。** 別リポジトリ (agent-skills) の仕事 ([ADR 0005](adr/0005-drop-ai-skills.md))
- **GUI でしか変えられない設定を無理にコード化すること。** 書き出せるものだけ持つ (Arq は Files タブの Export だけ)

## どこへ向かうか

- macOS / Ubuntu / Windows のどれでも、入口 1 本で同じ考え方のセットアップが通る (Windows は `install.ps1` が先行していて、sh 側との共通化は未着手)
- 常用機 (MacBook Pro / Mac mini / Windows) の差分が、`*.local` とチャンクの選択だけで説明できる

# windows

Windows のセットアップ。入口は **`windows/install.ps1`**。

`install.sh` は Mac / Ubuntu 専用 (Git Bash から実行すると案内を出して止まる)。

```powershell
git clone git@github.com:ken-ty/dotfiles.git
powershell -ExecutionPolicy Bypass -File dotfiles\windows\install.ps1
```

## 管理しているもの

| ファイル名 | 説明 |
| --- | --- |
| `install.ps1` | Windows のブートストラップ。「git を入れる」から「Claude Code でスキルが有効になる」まで |
| `Microsoft.PowerShell_profile.ps1` | PowerShell の profile。`$PROFILE` から dot-source される |

## install.ps1 が行う処理

「git を入れる」から「Claude Code でスキルが有効になる」までを一本で通す:

1. winget で Git / GitHub CLI / ghq / Node.js / fzf
2. Discord（任意）
3. `core.sshCommand` を Windows OpenSSH に向ける ── **非 ASCII のユーザ名では必須**。
   これが無いと、鍵も登録も正しいのに `publickey` 拒否になる
4. ed25519 鍵の生成 → 公開鍵を表示 → 登録待ち → `ssh -T` で疎通確認
5. `gh auth status`（ログインはブラウザ対話なので手動）
6. agent-skills / agent-skills-store を clone して配線
7. `$PROFILE` に `windows/Microsoft.PowerShell_profile.ps1` を dot-source する 1 行を追記
8. PSFzf（任意。Ctrl+r の履歴 fuzzy search に要る）

**symlink の権限が無ければ、6 で失敗せずに打つべきコマンドを表示して飛ばす。**
開発者モードか sudo のどちらかを有効にして再実行すれば、そこだけ進む。

`install.sh` と違い**設定ファイルの symlink は張らない**（Windows は symlink に特権が要り、
`.zshrc` も使わないため）。共通化は後回しにしてある。
PowerShell profile だけは、`$PROFILE` に dot-source の 1 行を追記することで
symlink 相当の「リポジトリを直せば即反映」を得ている。既存の `$PROFILE` は上書きしない。

## PowerShell の fzf 連携

`.zshrc` の fzf まわりと同じ操作感を Windows にも用意してある。

| キー | 動作 | 対応する `.zshrc` |
| --- | --- | --- |
| `Ctrl+]` | `ghq list -p` を fzf で絞り込んで移動 | `cd-ghq-list--fzf` |
| `Ctrl+r` | コマンド履歴を fzf で絞り込み | `fzf-select-history` |
| `g` | `Ctrl+]` と同じ（エイリアス） | — |

**`Ctrl+]` が届かないターミナル設定がある。** 反応しなければ `g` で運用するか、
profile の `-Chord` を書き換える。

profile に日本語コメントを書くなら **UTF-8 BOM 付きで保存する**。PowerShell 5.1 は
BOM 無しを CP932 として読むため、BOM を落とすとコメントが化けて構文エラーになる。

## 文字コード

**PowerShell 5.1 の `$OutputEncoding` の既定は `ASCIIEncoding`。** ネイティブコマンド
同士をパイプすると PowerShell が間で文字列を再エンコードするため、非 ASCII がすべて
`?` に潰れる。profile でこれを UTF-8 に固定している。

表示が崩れるだけではない。**読んで書き戻す経路に乗せるとデータが壊れる**:

```powershell
bw get item $id | jq ... | bw edit item $id   # notes の日本語が ??? で保存される
```

`[Console]::OutputEncoding` は utf-8 なのに `$OutputEncoding` だけが ASCII、という
非対称なので気づきにくい。`powershell -NoProfile` で再現する。

**BOM 無しを明示するのが要点。** `[System.Text.Encoding]::UTF8` は preamble を持つので、
そのまま使うとネイティブコマンドの stdin 先頭に BOM (U+FEFF) が載り、受け側の JSON
パースが落ちる。

関連して PS 5.1 で踏むもの:

- `jq -r '.[] | "\(.id) \(.name)"'` の**ダブルクォートは PS が食う**。
  `'.[] | [.id,.name] | @tsv'` のように書けば通る
- **環境変数経由で非 ASCII をネイティブ exe に渡すと ANSI で渡り化ける**（`ñ` → `n`）。
  `jq --arg` は化けない
- `... | bw encode` のような**パイプ経由の base64 化は BOM が混ざる**。
  `[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))` で避ける

コンソールが 65001 でも**システム ACP が 932** なら、別のターミナルや別マシンでは 932 で
開きうる。profile で毎回固定するのはそのため。

詰まりどころの詳細は `my-windows-setup` スキル
（[agent-skills-store](https://github.com/ken-ty/agent-skills-store)）にある。

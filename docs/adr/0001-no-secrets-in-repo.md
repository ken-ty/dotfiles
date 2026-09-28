# 0001. 秘密はリポジトリに入れない

- 状態: 採用
- 時期: 2026-03 (#47)、2026-08 (#52) で方針化
- 関連: [#47](https://github.com/ken-ty/dotfiles/pull/47) [#48](https://github.com/ken-ty/dotfiles/pull/48) [#52](https://github.com/ken-ty/dotfiles/pull/52)

## 背景

`git/.gitconfig.local` に秘匿情報を書く運用だったが、ファイル自体を追跡していた。MCP サーバにはトークンが要るものがある。

## 決定

- 秘密の**値**はリポジトリに置かない。置くのは名前 (Keychain のサービス名など) だけ
- 値は実行時に `security find-generic-password` や Bitwarden から取る (`mcp/servers.json` の chatwork がその形)
- 機械ごとの値は `*.local` に書き、`.gitignore` で外す
- `claude mcp add --header` のように、追加した時点で秘密が平文で焼き付く経路は宣言に載せない

## 結果

- 新しい機械では秘密の登録が手作業で残る。`mcp/install.sh` は足りない秘密を検出し、登録コマンドを表示して飛ばす
- 2026-09-28 の公開前検査 (gitleaks と履歴の grep) で、値が 1 度も commit されていないことを確認した

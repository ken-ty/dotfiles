# 0003. Homebrew を技術ごとのチャンクに分け、推奨 / full / select で選ぶ

- 状態: 採用
- 時期: 2026-09-14
- 関連: [#57](https://github.com/ken-ty/dotfiles/pull/57)

## 背景

`install.sh` は symlink しか張らず、Homebrew もプラグインも入れていなかった。Brewfile が 1 枚で、サーバーに流すと mysql・virtualbox・VS Code 拡張 58 個まで入った。

## 決定

- `macos/chunks/<名前>/Brewfile` に分け、1 行目の `# desc:` を一覧に出す。入れた後の 1 手は任意の `install.sh`
- `install.sh --mode recommended|full|select` と `--yes`。サーバーには推奨だけ

## 結果

- チャンクはディレクトリを 1 つ作るだけで増やせる
- どのチャンクにも属さない行を作らない (旧 Brewfile との突合で確認した)

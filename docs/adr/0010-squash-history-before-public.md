# 0010. 公開の前に履歴を「最初の commit + 公開時点」の 2 つにまとめる

- 状態: 採用
- 時期: 2026-09-28

## 背景

private で育てたリポジトリを public にする。履歴には private 前提で書いた途中経過が 185 commit 分あった (秘密は gitleaks と grep で 0 件)。

## 決定

- 最初の commit (2023-04-16) だけは残す。いつから続けているかが分かるように
- それ以降は公開時点の 1 commit にまとめ、force push する
- どう育ったかは commit ではなく `docs/HISTORY.md`、`docs/VISION.md`、この ADR に残す
- 書き換える前の全履歴は git bundle にして手元に退避した

## 結果

- GitHub の PR と Issue は残るので、各 PR の本文と diff は引き続き読める。HISTORY と ADR から PR にリンクしている
- 既存の clone (MBP / mini の `~/dotfiles` など) は `git fetch && git reset --hard origin/main` で取り直す必要がある

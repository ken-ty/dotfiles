# 0005. AI スキルのセットアップを dotfiles から外す

- 状態: 採用
- 時期: 2026-08-25
- 関連: [#49](https://github.com/ken-ty/dotfiles/pull/49) [#54](https://github.com/ken-ty/dotfiles/pull/54)

## 背景

`install.sh` は ai-skills を clone して「スキルが入った」と表示していたが、そのリポジトリは保守を止めていた。スキル管理は agent-skills に移っていた。

## 決定

`install.sh` から ai-skills の clone を削除し、必要なら agent-skills を入れるよう 1 行案内するだけにする。

## 結果

- sh と ps1 の非対称が残る (`windows/install.ps1` は agent-skills まで面倒を見る)。共通化は未着手

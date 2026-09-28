# 0004. Docker Desktop をやめて colima にする

- 状態: 採用
- 時期: 2026-09-14
- 関連: [#56](https://github.com/ken-ty/dotfiles/pull/56)

## 背景

Docker Desktop は常駐 10 プロセス (約 440 MB) と 1.7 GB の本体で重く、使っていたのは devcontainer と compose だけだった。

## 決定

`colima` `docker` `docker-buildx` `docker-compose` の 4 つを `docker` チャンクで入れる。Docker Desktop が入っている機械ではチャンクを飛ばす。

## 結果

- Docker Desktop を消すと `docker` CLI の symlink ごと消えるので、CLI とプラグインを別に入れる必要がある
- colima は使うときだけ起動する

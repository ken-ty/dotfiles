# 0011. 配布後のヘルスチェックを install に組み込み、壊れていたら install を失敗させる

- 状態: 採用
- 時期: 2026-10-02
- 関連: [ADR 0002](0002-declaration-is-source-of-truth.md)

## 背景

ずれを読み取りだけで見る経路 (ADR 0002) は `mcp/doctor.sh` と `defaults.sh --check` にしか無く、`install.sh` が張る symlink と Brewfile の差は誰も見ていなかった。`install.sh` は最後に「All steps completed successfully!」と出すが、張ったものが揃っているかは確かめていなかった。

実際、2026-10-02 に MBP で初めて流したところ、`~/.default-gems` は repo に無いファイルを指す壊れたリンクで、`~/.config/git/ignore` は symlink ではなく実ファイルだった。どちらもエラーにならないので気づく機会が無かった。

## 決定

- `macos/doctor.sh` を置く。読み取りのみ。symlink・Brewfile・defaults・MCP を 1 行ずつ `ok` / `warn` / `bad` で出し、bad があれば exit 1
- symlink の一覧は `macos/links.conf` の表に出し、`install.sh` と `doctor.sh` が同じ表を読む。張るものの宣言を 2 箇所に書かない
- bad は「`install.sh` が張ったはずのものが壊れている」ときだけ。チャンク・defaults・MCP は入れるかを選べるので、差は warn
- `install.sh` の最後で `doctor.sh` を流し、bad なら `install.sh` も非 0 で終わる
- Windows の `install.ps1` は、最後に案内していた `agent-skills doctor` を実際に流す。結果では失敗にしない (symlink の権限が無くて Step 6 を飛ばした機械では BAD が出るのが想定どおりなので)

## 採らなかった案

- **doctor を別コマンドのままにし、README で案内するだけにする。** `mcp/doctor.sh` がその形で、流すかどうかが人の記憶に依る。上の 2 件も、案内だけでは見つからなかった
- **symlink の一覧を `doctor.sh` にも書く。** 張るものを足したときに片方だけ直す事故が起きる。`links.conf` の表を共有すれば 1 行で済む
- **Brewfile の差も bad にする。** どのチャンクを選んだかを記録していないので、入れていないチャンクと入れ損ねたチャンクを区別できない。bad にすると、推奨だけ入れたサーバーで `install.sh` が毎回失敗する
- **選んだチャンクを記録して、それだけを bad で見る。** 記録ファイルという新しい状態が増え、機械の上で手で `brew uninstall` したときに記録と実態がずれる。warn で全チャンクを見せれば足りる
- **doctor が bad を見つけたら直す (`--fix`)。** 直すのは `install.sh` の仕事で、冪等なのでもう一度流せばよい。doctor は読み取りだけに保つ (ADR 0002)

## 結果

- `install.sh` が成功した機械では、張ったはずの symlink が揃っていることが保証される
- `install.sh` は MCP の確認 (`claude mcp list`) の分だけ遅くなる。MBP で十数秒
- repo に無いファイルを指す古いリンク (`~/.default-gems`) は warn に留める。`install.sh` も張る元が無ければ SKIP するので、bad にすると `install.sh` で直せない理由で毎回失敗する
- `links.conf` の `asdf/.default-gems` の行は、`install.sh` の元のループをそのまま写したもので、張る元は repo に無い。消すかどうかは別に決める

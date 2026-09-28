# 0009. Arq の除外は「/Users 丸ごと − フルパスの除外」で持つ

- 状態: 採用
- 時期: 2026-09-28
- 関連: [#77](https://github.com/ken-ty/dotfiles/pull/77)

## 背景

Arq の日次バックアップが 5〜8 時間かかっていた。除外は画面でしか見えず、変更履歴が無かった。

## 決定

- 守るものを並べる方式にはしない。守るものの足し忘れは復元のときにしか気づけないが、除外の足し忘れは翌朝のログのファイル数で気づける
- 足す除外はフルパスで書き、アプリの状態を含まず再取得できるものだけにする
- Files タブの Export で書き出した JSON を `macos/arq/users.json` に置き、編集して Import する

## 結果

- スケジュールや保持期間など Files タブ以外の設定は JSON に含まれない
- 既存ルールには短い名前のパターン (`target`、`Cache` など) が残っている。2026-09-28 に `find` で当たり先を点検し、守りたいものに当たっていた 3 行だけを直した
  - `.android` → `~/.android/avd` と `~/.android/cache` に絞る。`debug.keystore`・`adbkey`・`maps.key` を守るため
  - `*/Library/Developer` → シミュレータ・DerivedData・DeviceSupport などフルパス 9 行に分ける。Archives と `UserData` (Provisioning Profiles、キーバインド) を守るため
  - `*.xcworkspace` → 削除。git 管理外のプロジェクトで `Runner.xcworkspace` が失われ、復元しても Xcode で開けなくなるため。ユーザー固有の状態は `xcuserdata` で除外済み
  - 残りの短い名前 (`target`、`Cache`、`Caches`、`Logs`、`Pods`、`.gradle` など) は、当たり先がすべて再生成できるものだったので据え置く

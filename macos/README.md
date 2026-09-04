# macos

「システム設定」で手で触る項目のうち、`defaults` コマンドで再現できるものを集めています。
新しいマシンで一度流せば、同じ状態になります。

```bash
bash macos/defaults.sh
```

書き込まずに差分だけ見るとき:

```bash
bash macos/defaults.sh --check
```

## 何を管理しているか

| 設定 | 値 | 理由 |
| --- | --- | --- |
| Mission Control: 最新の使用状況に基づいて操作スペースを自動的に並べ替える | オフ | オンだと Cmd+Tab で別スペースのアプリに飛んだだけでスペースの並びが変わり、「何番目に何を置いたか」で管理できなくなる |

## 項目を足すとき

`defaults.sh` の `SETTINGS` 配列に 1 行足します。書式は `domain|key|type|value|説明`。

どのキーか分からないときは、変更前後の全 defaults を取って差分を見るのが早いです。

```bash
defaults read > /tmp/before.plist
# システム設定で手で切り替える
defaults read > /tmp/after.plist
diff /tmp/before.plist /tmp/after.plist
```

## ここで管理しないもの

- **スペースへのアプリの割り当て** (Dock のアイコン右クリック > オプション > 割り当て先)。
  `com.apple.spaces` に UUID 付きで書かれ、マシンをまたいで再現できないので手で設定します。
- **Ctrl+数字 で操作スペースへ直接移動** (キーボード > キーボードショートカット > Mission Control)。
  `com.apple.symbolichotkeys` に書かれますが構造が壊れやすいので、手で有効にします。

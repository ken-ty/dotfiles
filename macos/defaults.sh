#!/bin/bash

# macos/defaults.sh
#
# macOS の「システム設定」で手で触る項目のうち、defaults コマンドで
# 再現できるものをここに集めます。新しいマシンで一度流せば同じ状態になります。
#
# 冪等です。既に同じ値ならその項目は飛ばし、何も変わらなければ Dock も再起動しません。
#
#   bash macos/defaults.sh          # 適用する
#   bash macos/defaults.sh --check  # 差分を報告するだけ (書き込まない)

set -eu

check_only=false
[ "${1:-}" = "--check" ] && check_only=true

[ "$(uname)" = "Darwin" ] || { echo "ERROR: macOS 専用です。" >&2; exit 1; }

# 項目の一覧。書式:  domain|key|type|value|説明
#
# type は defaults write の -bool / -int / -string に対応。
# 「システム設定」のどこにあるかを説明に書いておくと、手で戻すときに迷いません。
SETTINGS=(
    # Mission Control: 操作スペースを最近使った順に自動で並べ替える → オフ
    # (デスクトップとDock > Mission Control > 最新の使用状況に基づいて操作スペースを自動的に並べ替える)
    # オンだと Cmd+Tab で別スペースのアプリへ飛んだだけで並びが崩れ、
    # 「6 番目に置いたターミナルが 2 番目に来る」が起きる。
    "com.apple.dock|mru-spaces|bool|false|Spaces を最近使った順に並べ替えない"
)

# current_value: いまの値を defaults read で取る。未設定なら空文字
current_value() { defaults read "$1" "$2" 2> /dev/null || true; }

# normalize: 比較用に値を揃える。bool は 1/0 に寄せる
normalize() {
    case "$1" in
        true|TRUE|yes|YES|1) echo 1 ;;
        false|FALSE|no|NO|0) echo 0 ;;
        *) echo "$1" ;;
    esac
}

changed=0
same=0
restart_dock=false

for line in "${SETTINGS[@]}"; do
    IFS='|' read -r domain key type value desc <<< "$line"

    now=$(normalize "$(current_value "$domain" "$key")")
    want=$(normalize "$value")

    if [ "$now" = "$want" ]; then
        echo "  = $desc ($domain $key = $value)"
        same=$((same + 1))
        continue
    fi

    if $check_only; then
        echo "  ! $desc ($domain $key: ${now:-未設定} -> $value)"
    else
        defaults write "$domain" "$key" "-$type" "$value"
        echo "  + $desc ($domain $key: ${now:-未設定} -> $value)"
    fi
    changed=$((changed + 1))
    [ "$domain" = "com.apple.dock" ] && restart_dock=true
done

echo
if $check_only; then
    echo "一致 $same / 差分 $changed"
    exit 0
fi

# defaults write しただけでは Dock (Mission Control を含む) は読み直さない
if $restart_dock; then
    killall Dock
    echo "Dock を再起動しました (Mission Control に反映するため)。"
fi

echo "適用 $changed / 据え置き $same"

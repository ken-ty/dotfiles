#!/bin/bash

# macos/doctor.sh
#
# install.sh が作るものが実機で揃っているかを検査します。何も変更しません。読み取りだけです。
#
#   bash macos/doctor.sh
#
# 見るもの:
#   link      macos/links.conf の symlink が $HOME/dotfiles の正しい先を指しているか
#   brew      macos/chunks/*/Brewfile と実機の差 (brew bundle check)
#   defaults  macos/defaults.sh の宣言と実機の差 (defaults.sh --check)
#   mcp       mcp/doctor.sh の結果
#
# 1 項目 1 行で ok / warn / bad を出し、最後に件数を出します。
# 終了コード: bad が 1 つでもあれば 1。warn だけなら 0。使い方の誤りは 2。
#
# bad は「install.sh が張ったはずのものが壊れている」ときだけ。入れるかどうかを
# 選べるもの (チャンク、defaults、MCP) の差は warn に留めます。
# Ubuntu でも動きます (brew と defaults は無ければ飛ばす)。

set -eu

case "${1:-}" in
    "") ;;
    -h|--help) sed -n '3,20p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# symlink の指す先。install.sh と同じく $HOME/dotfiles (配置先)。
# ghq の正本から流しても、見るのは配置先へのリンク。
DOT_DIR="${DOT_DIR:-$HOME/dotfiles}"

n_ok=0
n_warn=0
n_bad=0

ok()   { printf 'ok    %s\n' "$*"; n_ok=$((n_ok + 1)); }
warn() { printf 'warn  %s\n' "$*"; n_warn=$((n_warn + 1)); }
bad()  { printf 'bad   %s\n' "$*"; n_bad=$((n_bad + 1)); }

has() { type "$1" > /dev/null 2>&1; }

case "$(uname)" in
    Darwin) os=mac ;;
    Linux) os=ubuntu ;;
    *) os=other ;;
esac

# -----------------------------------------------
# link: install.sh の Step 3 と同じ表を読む
# -----------------------------------------------
check_links() {
    local src dest name when want now gui
    while IFS='|' read -r src dest name when; do
        case "$src" in ''|'#'*) continue ;; esac
        gui=false
        case "$when" in *-gui) gui=true; when=${when%-gui} ;; esac
        [ "$when" = all ] || [ "$when" = "$os" ] || continue

        want="$DOT_DIR/$src"
        dest="$HOME/$dest"

        if [ ! -e "$want" ]; then
            # install.sh も SKIP する。前に張ったリンクが残っていれば、それは手で消してよい
            if [ -L "$dest" ]; then
                warn "link: $name — 張る元が repo に無い ($want)。$dest は前に張った名残り"
            else
                warn "link: $name — 張る元が repo に無い ($want)"
            fi
        elif [ -L "$dest" ]; then
            now=$(readlink "$dest")
            if [ ! -e "$dest" ]; then
                bad "link: $name — 壊れたリンク ($dest -> $now)"
            elif [ "$now" = "$want" ] || [ "$dest" -ef "$want" ]; then
                ok "link: $name"
            else
                bad "link: $name — 別の先を指している ($dest -> $now。期待: $want)"
            fi
        elif [ -e "$dest" ]; then
            # install.sh の確認に n と答えるとこうなる。壊れてはいないので warn
            warn "link: $name — symlink ではなく実ファイル ($dest)。張るなら install.sh を流す"
        elif $gui; then
            warn "link: $name — 無い ($dest)。サーバーなら想定どおり"
        else
            bad "link: $name — 無い ($dest)"
        fi
    done < "$REPO_DIR/macos/links.conf"
}

# -----------------------------------------------
# brew: どのチャンクを選んだかは記録していないので、全チャンクを見て差は warn
# -----------------------------------------------
check_brew() {
    if ! has brew && [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    if ! has brew; then
        if [ "$os" = mac ]; then warn "brew: Homebrew が無い"; fi
        return 0
    fi
    local dir c out missing
    for dir in "$REPO_DIR"/macos/chunks/*/; do
        c=$(basename "$dir")
        [ -f "$dir/Brewfile" ] || continue
        # check は何も入れない。auto update も止める (読み取りだけにするため)。
        # 足りないものの一覧 (→ の行) は stderr に出る
        if out=$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --file="$dir/Brewfile" 2>&1); then
            ok "brew: chunk $c"
        else
            missing=$(grep -c '^→' <<< "$out" || true)
            warn "brew: chunk $c — ${missing} 件が未導入か古い (brew bundle check --verbose --file=macos/chunks/$c/Brewfile)"
        fi
    done
}

# -----------------------------------------------
# defaults: defaults.sh --check の 1 行ずつを読み替える
# -----------------------------------------------
check_defaults() {
    [ "$os" = mac ] || return 0
    local line
    while IFS= read -r line; do
        case "$line" in
            '  = '*) ok "defaults: ${line#  = }" ;;
            '  ! '*) warn "defaults: ${line#  ! } (bash macos/defaults.sh で揃う)" ;;
        esac
    done < <(bash "$REPO_DIR/macos/defaults.sh" --check)
}

# -----------------------------------------------
# mcp: mcp/doctor.sh を呼んで 1 行ずつ読み替える
# MCP の配線は install.sh ではなく mcp/install.sh なので、差は warn
# -----------------------------------------------
check_mcp() {
    if ! has claude || ! has jq; then
        warn "mcp: claude か jq が無いので見ない"
        return 0
    fi
    local out line rest
    if ! out=$(bash "$REPO_DIR/mcp/doctor.sh" 2>&1); then
        warn "mcp: mcp/doctor.sh が失敗した ($(tail -n 1 <<< "$out"))"
        return 0
    fi
    while IFS= read -r line; do
        rest=$(sed -E 's/^ +[A-Z]+ +//; s/ +$//' <<< "$line")
        case "$line" in
            '  OK '*)         ok   "mcp: $rest" ;;
            '  MISSING '*)    warn "mcp: $rest — 登録されていない (mcp/README.md)" ;;
            '  FAILED '*)     warn "mcp: $rest — 繋がらない" ;;
            '  UNDECLARED '*) warn "mcp: $rest — servers.json に無い" ;;
        esac
    done <<< "$out"
}

check_links
check_brew
check_defaults
check_mcp

echo
echo "ok $n_ok / warn $n_warn / bad $n_bad"
[ "$n_bad" -eq 0 ]

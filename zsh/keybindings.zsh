# キーバインドを表 (zsh/keybindings.conf) で管理する。
#
#   読み込み: .zshrc が source する。fzf (~/.fzf.zsh) より後、fzf 付属の widget が
#             定義されたあとに読むこと。表にある fzf の行はそれを前提にしている
#   上書き:   ~/.zsh-keybindings.local (git 管理外、同じ書式、後勝ち)
#   操作:     keybind list | on <key> [widget] | off <key> [widget] | edit | reload
#
# 表の書式は fstab と同じ「空白区切り + # コメント」。zsh の while read で読めるので
# jq も yq も要らず、無い機械でも壊れない。

typeset -g KEYBIND_DIR="${${(%):-%N}:A:h}"
typeset -g KEYBIND_CONF="${KEYBIND_DIR}/keybindings.conf"
typeset -g KEYBIND_LOCAL="${HOME}/.zsh-keybindings.local"

# 表の中身。キーは "<key> <widget>"。
typeset -gA _kb_state _kb_desc _kb_src
typeset -ga _kb_order

# widget の定義を読む (1 関数 1 ファイル)。
_keybind_load_widgets() {
  local f
  for f in "${KEYBIND_DIR}"/widgets/*.zsh(N); do
    source "$f"
  done
}

# 表 1 枚を読んで配列に積む。$2 は出どころの印 (conf / local)。
_keybind_read_table() {
  local file=$1 src=$2 key widget state desc id
  [ -f "$file" ] || return 0
  while read -r key widget state desc; do
    [[ -z $key || $key == '#'* ]] && continue
    id="$key $widget"
    (( ${+_kb_state[$id]} )) || _kb_order+=("$id")
    _kb_state[$id]=$state
    _kb_src[$id]=$src
    # local は説明を省いてよい。省いたら conf の説明を残す
    [[ -n $desc ]] && _kb_desc[$id]=$desc
  done < "$file"
}

# 1 行ぶんを実際の bindkey に反映する。
_keybind_apply_one() {
  local key=$1 widget=$2 state=$3
  case $state in
    on)
      if (( ${+widgets[$widget]} )); then
        bindkey "$key" "$widget"
      fi
      ;;
    off)
      # その key がこの widget に縛られているときだけ外す (別の widget を巻き込まない)
      if [[ "$(bindkey "$key" 2>/dev/null)" == *" $widget" ]]; then
        bindkey -r "$key"
      fi
      ;;
  esac
}

# 全部読み直して反映する。
keybind-reload() {
  _kb_state=() _kb_desc=() _kb_src=() _kb_order=()
  _keybind_load_widgets
  _keybind_read_table "$KEYBIND_CONF" conf
  _keybind_read_table "$KEYBIND_LOCAL" local
  local id
  for id in "${_kb_order[@]}"; do
    _keybind_apply_one "${id%% *}" "${id#* }" "${_kb_state[$id]}"
  done
}

# 表と実測を並べて出す。
_keybind_list() {
  local id key widget state actual mark
  printf '%-6s %-22s %-5s %-5s %-8s %s\n' KEY WIDGET STATE 実測 出どころ 説明
  for id in "${_kb_order[@]}"; do
    key=${id%% *} widget=${id#* } state=${_kb_state[$id]}
    actual="$(bindkey "$key" 2>/dev/null)"
    if [[ $actual == *" $widget" ]]; then mark='bound'
    elif (( ! ${+widgets[$widget]} )); then mark='no-widget'
    else mark='-'
    fi
    printf '%-6s %-22s %-5s %-9s %-8s %s\n' "$key" "$widget" "$state" "$mark" "${_kb_src[$id]}" "${_kb_desc[$id]:-}"
  done
}

# ~/.zsh-keybindings.local に 1 行足す (同じ key+widget の行があれば置き換える)。
_keybind_write_local() {
  local key=$1 widget=$2 state=$3 tmp
  tmp="${KEYBIND_LOCAL}.tmp.$$"
  {
    [ -f "$KEYBIND_LOCAL" ] && awk -v k="$key" -v w="$widget" '!($1==k && $2==w)' "$KEYBIND_LOCAL"
    printf '%s\t%s\t%s\n' "$key" "$widget" "$state"
  } > "$tmp" && mv "$tmp" "$KEYBIND_LOCAL"
}

# key だけ指定されたら、表でその key に on になっている widget を探す。
_keybind_widget_for() {
  local key=$1 id
  for id in "${_kb_order[@]}"; do
    [[ ${id%% *} == "$key" && ${_kb_state[$id]} == on ]] && { printf '%s' "${id#* }"; return 0; }
  done
  for id in "${_kb_order[@]}"; do
    [[ ${id%% *} == "$key" ]] && { printf '%s' "${id#* }"; return 0; }
  done
  return 1
}

keybind() {
  local cmd=${1:-list} key widget
  case $cmd in
    list) _keybind_list ;;
    on|off)
      key=$2 widget=$3
      [ -n "$key" ] || { echo "usage: keybind $cmd <key> [widget]" >&2; return 2; }
      [ -n "$widget" ] || widget=$(_keybind_widget_for "$key") || { echo "keybind: $key は表に無い。widget も指定して" >&2; return 1; }
      _keybind_write_local "$key" "$widget" "$cmd"
      keybind-reload
      echo "keybind: $key $widget → $cmd (この機械だけ。$KEYBIND_LOCAL)"
      ;;
    edit) "${EDITOR:-vim}" "$KEYBIND_CONF" && keybind-reload ;;
    reload) keybind-reload ;;
    *) echo "usage: keybind [list|on <key> [widget]|off <key> [widget]|edit|reload]" >&2; return 2 ;;
  esac
}

keybind-reload

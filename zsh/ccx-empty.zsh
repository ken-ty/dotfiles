# ccx empty: 一度も Ken の入力を受けていない空の bg セッションを見つけて消す。.zshrc の ccx から呼ばれる。
# 想定する空: 機械の起動時に自動で立ったもの、「全セッション開き直して」の復帰で新しく作られたもの。
# 起こし直した (respawn) だけのセッションは、前に入力があるので空ではない。
#
# 候補を一覧してから聞き、Enter で claude rm する。それ以外の入力で中止。
#   -n, --dry-run  一覧だけ出す (端末でないとき、たとえば他のスクリプトから呼んだときも一覧だけ)
#   -y, --yes      聞かずに消す
# bg は claude rm で消す。interactive (VS Code・Desktop・端末) は claude rm が効かないので、候補には出すが
# 自動では止めず、終わらせるコマンド (kill <pid>) を表示する。
# 未 push・未コミットのある worktree は claude rm 自身が拒むので、そのまま残る (消す指示は付けない)。
#
# 判定は下の jq の表 2 つで決まる。条件を足すときは表に 1 行足す。
#   must  : 全部 ok なら候補。1 つでも外れたら対象外 (表示しない)
#   doubt : must を通っても 1 つでも hit したら候補にせず「要確認」に回す
# 表が見る値 (1 セッション 1 オブジェクト):
#   claude agents --json --all の 1 行 (id, kind, pid, name, state, status, sessionId …)
#   .job    = ~/.claude/jobs/<id>/state.json (state, detail, needs …)。無ければ {}
#   .inputs = 会話ログ全体での Ken の入力の件数。会話ログが無ければ 0 (一度も話していない)
#   .bridge = ~/.claude/sessions/<pid>.json の bridgeSessionId。claude.ai の URL (…/code/<これ>) と突き合わせる

_ccx_empty_rules='
def must: [
  {why: "Ken の入力が一度も無い",         ok: (.inputs == 0)},
  {why: "いま応答を作っていない",         ok: (.status != "busy")},
  {why: "指す手段がある (bg は id、それ以外は pid)", ok: (if .kind == "background" then .id != null else .pid != null end)}
];
def doubt: [
  {why: "needs (Ken への依頼) がある",    hit: ((.job.needs // "") != "")}
];
map(select([must[].ok] | all))
| map(. + {doubts: [doubt[] | select(.hit) | .why]})
| {rm: map(select(.doubts == [])), check: map(select(.doubts != []))}
'

# Ken の入力を数える。入力 = type=user で content が文字列。
# isMeta (フックの差し込み・他セッションからのメッセージ) と task-notification は数えない。
_ccx_empty_inputs() {
  (( $# )) || { echo 0; return; }
  jq -n '[inputs
    | select(.type == "user" and (.message.content | type) == "string")
    | select(.isMeta != true and .origin.kind != "task-notification")]
    | length' "$@"
}

_ccx_empty() {
  local mode=ask
  case "$1" in
    "") [[ -t 0 ]] || mode=list ;;
    -n|--dry-run) mode=list ;;
    -y|--yes) mode=yes ;;
    *) echo "usage: ccx empty [-n|--dry-run] [-y|--yes]" >&2; return 1 ;;
  esac

  # 判定の材料を 1 セッション 1 行の JSON にする
  local facts=() a id sid job pidf logs
  for a in ${(f)"$(claude agents --json --all | jq -c '.[]')"}; do
    id=$(jq -r '.id // ""' <<<"$a")
    sid=$(jq -r '.sessionId // ""' <<<"$a")
    job=~/.claude/jobs/$id/state.json
    logs=()
    [[ -n $sid ]] && logs=(~/.claude/projects/*/$sid.jsonl(N))
    [[ -n $id && -f $job ]] || job=/dev/null
    pidf=~/.claude/sessions/$(jq -r '.pid // "none"' <<<"$a").json
    [[ -f $pidf ]] || pidf=/dev/null
    facts+=("$(jq -c --slurpfile job "$job" --slurpfile ses "$pidf" \
      --argjson inputs "$(_ccx_empty_inputs $logs)" \
      '. + {job: ($job[0] // {}), bridge: ($ses[0].bridgeSessionId // null), inputs: $inputs}' <<<"$a")")
  done

  local result
  result=$(printf '%s\n' $facts | jq -s "$_ccx_empty_rules") || return 1

  echo "消す候補:"
  jq -r '.rm[] | "  \(.id // "pid \(.pid)")\t\(.kind)\t\(.name)\t\(if .bridge then "https://claude.ai/code/\(.bridge)" else "" end)"' <<<"$result"
  echo "要確認 (候補に入れていない):"
  jq -r '.check[] | "  \(.id // "pid \(.pid)")\t\(.kind)\t\(.name)\t\(.doubts | join(" / "))"' <<<"$result"

  local ids=(${(f)"$(jq -r '.rm[] | select(.kind == "background") | .id' <<<"$result")"})
  local pids=(${(f)"$(jq -r '.rm[] | select(.kind != "background") | .pid' <<<"$result")"})
  # interactive は claude rm が効かない。自動では止めず、終わらせるコマンドを出す
  (( $#pids )) && echo "interactive の空は claude rm が効かない。終わらせるなら: kill $pids"
  if (( ! $#ids )); then
    (( $#pids )) || echo "消す候補はありません"
    return 0
  fi
  case $mode in
    list) echo "消すには: ccx empty"; return 0 ;;
    ask)
      local ans
      read -r "ans?bg $#ids 本を claude rm します。Enter で実行、それ以外で中止: "
      [[ -z $ans ]] || { echo "中止しました"; return 0; } ;;
  esac
  local i; for i in $ids; do claude rm "$i"; done
}

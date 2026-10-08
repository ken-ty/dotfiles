# ccx empty: 一度も Ken の入力を受けていない空の bg セッションを見つけて消す。.zshrc の ccx から呼ばれる。
# 想定する空: 機械の起動時に自動で立ったもの、「全セッション開き直して」の復帰で新しく作られたもの。
# 起こし直した (respawn) だけのセッションは、前に入力があるので空ではない。
#
# 候補を一覧してから聞き、Enter で claude rm する。それ以外の入力で中止。
#   -n, --dry-run  一覧だけ出す (端末でないとき、たとえば他のスクリプトから呼んだときも一覧だけ)
#   -y, --yes      聞かずに消す
# claude rm は bg セッションにしか効かないので、interactive (VS Code・端末) の空は「要確認」に出すだけ。
# 未 push・未コミットのある worktree は claude rm 自身が拒むので、そのまま残る (消す指示は付けない)。
#
# 判定は下の jq の表 2 つで決まる。条件を足すときは表に 1 行足す。
#   must  : 全部 ok なら候補。1 つでも外れたら対象外 (表示しない)
#   doubt : must を通っても 1 つでも hit したら候補にせず「要確認」に回す
# 表が見る値 (1 セッション 1 オブジェクト):
#   claude agents --json --all の 1 行 (id, kind, pid, name, state, status, sessionId …)
#   .job    = ~/.claude/jobs/<id>/state.json (state, detail, needs …)。無ければ {}
#   .inputs = 会話ログ全体での Ken の入力の件数。会話ログが無ければ 0 (一度も話していない)

_ccx_empty_rules='
def must: [
  {why: "Ken の入力が一度も無い",         ok: (.inputs == 0)},
  {why: "いま応答を作っていない",         ok: (.status != "busy")}
];
def doubt: [
  {why: "bg ではない (claude rm が効かない)", hit: (.kind != "background")},
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
  local facts=() a id sid job logs
  for a in ${(f)"$(claude agents --json --all | jq -c '.[]')"}; do
    id=$(jq -r '.id // ""' <<<"$a")
    sid=$(jq -r '.sessionId // ""' <<<"$a")
    job=~/.claude/jobs/$id/state.json
    logs=()
    [[ -n $sid ]] && logs=(~/.claude/projects/*/$sid.jsonl(N))
    [[ -n $id && -f $job ]] || job=/dev/null
    facts+=("$(jq -c --slurpfile job "$job" \
      --argjson inputs "$(_ccx_empty_inputs $logs)" \
      '. + {job: ($job[0] // {}), inputs: $inputs}' <<<"$a")")
  done

  local result
  result=$(printf '%s\n' $facts | jq -s "$_ccx_empty_rules") || return 1

  echo "消す候補:"
  jq -r '.rm[] | "  \(.id)\t\(.name)\t\(.state // "-")\t\(.cwd // "")"' <<<"$result"
  echo "要確認 (候補に入れていない):"
  jq -r '.check[] | "  \(.id // "pid \(.pid)")\t\(.name)\t\(.doubts | join(" / "))\t\(.cwd // "")"' <<<"$result"

  local ids=(${(f)"$(jq -r '.rm[].id' <<<"$result")"})
  if (( ! $#ids )); then
    echo "消す候補はありません"
    return 0
  fi
  case $mode in
    list) echo "消すには: ccx empty"; return 0 ;;
    ask)
      local ans
      read -r "ans?$#ids 本を claude rm します。Enter で実行、それ以外で中止: "
      [[ -z $ans ]] || { echo "中止しました"; return 0; } ;;
  esac
  local i; for i in $ids; do claude rm "$i"; done
}

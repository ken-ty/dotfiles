# ccx sweep: 何もしていない bg セッションを見つけて止める。.zshrc の ccx から呼ばれる。
#
# 既定は一覧を出すだけ (dry-run)。--yes を付けたときだけ候補を claude stop する。
# stop は会話を残す (claude attach <id> で戻せる)。rm はしない。
#
# 判定は下の jq の表 2 つで決まる。条件を足すときは表に 1 行足す。
#   must  : 全部 ok なら候補。1 つでも外れたら対象外 (表示しない)
#   doubt : must を通っても 1 つでも hit したら候補にせず「要確認」に回す
# 表が見る値 (1 セッション 1 オブジェクト):
#   claude agents --json の 1 行 (id, pid, name, state, status, startedAt, sessionId …)
#   .job    = ~/.claude/jobs/<id>/state.json (state, detail, needs …)。無ければ {}
#   .inputs = startedAt 以降の Ken の入力の件数。会話ログが見つからなければ null

_ccx_sweep_rules='
def must: [
  {why: "プロセスが動いている",           ok: (.pid != null)},
  {why: "いま応答を作っていない",         ok: (.status == "idle")},
  {why: "done か、起こしただけ",          ok: (.job.state == "done" or .job.detail == "(idle — send a prompt to start)")},
  {why: "起きてから Ken の入力が 0 件",   ok: ((.inputs // 0) == 0)}
];
def doubt: [
  {why: "detail が確認待ちに見える",      hit: ((.job.detail // "") | test("await|wait|confirm|decision|review|question|待ち|確認|質問|判断"; "i"))},
  {why: "needs (Ken への依頼) がある",    hit: ((.job.needs // "") != "")},
  {why: "会話ログが見つからない",         hit: (.inputs == null)}
];
map(select([must[].ok] | all))
| map(. + {doubts: [doubt[] | select(.hit) | .why]})
| {stop: map(select(.doubts == [])), check: map(select(.doubts != []))}
'

# startedAt (ミリ秒) 以降の Ken の入力を数える。
# 入力 = type=user で content が文字列。isMeta (フックの差し込み等) と task-notification は数えない。
_ccx_sweep_inputs() {
  local since=$1; shift
  (( $# )) || { echo null; return; }
  jq -n --argjson since "$since" '
    [inputs
     | select(.type == "user" and (.message.content | type) == "string")
     | select(.isMeta != true and .origin.kind != "task-notification")
     | select(.timestamp | (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) * 1000
                            + ((capture("\\.(?<ms>[0-9]{3})") | .ms | tonumber) // 0) >= $since)]
    | length' "$@"
}

_ccx_sweep() {
  local yes=0
  case "$1" in
    "") ;;
    -y|--yes) yes=1 ;;
    *) echo "usage: ccx sweep [--yes]" >&2; return 1 ;;
  esac

  # 判定の材料を 1 セッション 1 行の JSON にする
  local facts=() a id sid since job logs
  for a in ${(f)"$(claude agents --json | jq -c '.[] | select(.kind == "background" and .pid != null)')"}; do
    id=$(jq -r .id <<<"$a")
    sid=$(jq -r .sessionId <<<"$a")
    since=$(jq -r '.startedAt // 0' <<<"$a")
    job=~/.claude/jobs/$id/state.json
    logs=(~/.claude/projects/*/$sid.jsonl(N))
    [[ -f $job ]] || job=/dev/null
    facts+=("$(jq -c --slurpfile job "$job" \
      --argjson inputs "$(_ccx_sweep_inputs "$since" $logs)" \
      '. + {job: ($job[0] // {}), inputs: $inputs}' <<<"$a")")
  done

  local result
  result=$(printf '%s\n' $facts | jq -s "$_ccx_sweep_rules") || return 1

  echo "止める候補:"
  jq -r '.stop[] | "  \(.id)\t\(.name)\t\(.job.state // .state)\t\(.job.detail // "")"' <<<"$result"
  echo "要確認 (候補に入れていない):"
  jq -r '.check[] | "  \(.id)\t\(.name)\t\(.doubts | join(" / "))\t\(.job.detail // "")"' <<<"$result"

  local ids=(${(f)"$(jq -r '.stop[].id' <<<"$result")"})
  if (( ! $#ids )); then
    echo "止める候補はありません"
  elif (( yes )); then
    local i; for i in $ids; do claude stop "$i"; done
  else
    echo "止めるには: ccx sweep --yes  (stop は会話を残す。戻すのは claude attach <id>)"
  fi
}

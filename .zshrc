# パフォーマンスチューニング有効化するかどうか
ENABLE_PERFORMANCE_MEASUREMENT='FALSE' # 'TRUE' にすると起動のたびに zprof の表が出る。遅いと感じたときだけ

# パフォーマンス計測 開始
[ $ENABLE_PERFORMANCE_MEASUREMENT = 'TRUE' ] && zmodload zsh/zprof

# homebrew
export PATH="/opt/homebrew/bin:$PATH"



# 環境変数を設定 ここから {{{
  export LANG=ja_JP.UTF-8 # 言語は日本語を選択
  export EDITOR='vim' # エディタは vim を選択
# }}} 環境変数を設定 ここまで

# ローカル環境変数 (git 管理外。API キー等のシークレットや、この機械だけの設定を ~/.zshrc.local に書く) ここから {{{
  [ -f ~/.zshrc.local ] && source ~/.zshrc.local
# }}} ローカル環境変数 ここまで

# 履歴を設定 ここから {{{
  HISTFILE=$HOME/.zsh-history # history がターミナル終了でリセットされないように外部ファイルに保存する
  SAVEHIST=1000000 # 履歴ファイルに保存できるコマンド数
  HISTSIZE=1000000 # 履歴ファイルからメモリに読み込むコマンド数
  setopt EXTENDED_HISTORY # history に 時刻情報を付与
  setopt HIST_FIND_NO_DUPS # 重複コマンドは履歴には書き込むが矢印で辿る際はスキップする
  setopt SHARE_HISTORY # history を 複数のターミナルで共有する
  setopt HIST_IGNORE_ALL_DUPS  # 重複するコマンド行は古い方を削除
  setopt HIST_REDUCE_BLANKS # 余分な空白を削除して保存する
# }}} 履歴を設定 ここまで

# その他設定 ここから {{{
  setopt PRINT_EIGHT_BIT # 日本語ファイル名を表示可能にする
# }}} その他設定 ここまで

# バージョン管理ツールの読み込み ここから {{{
  export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH" # asdf 読み込む
  # # Flutter の パス通す
  # export PATH="$PATH:/Users/apple/develop/flutter/bin"
  # `dart pub global activate xxx` でインストールしたコマンドを使えるようにする.
  # fvm や、 flutterfire の為に必要
  export PATH="$PATH":"$HOME/.pub-cache/bin"
  # asdf-flutter の為に FLUTTER_ROOT を設定する
  # @see https://github.com/oae/asdf-flutter の README
  # flutter を入れていない機械 (サーバー) では飛ばす
  if asdf plugin list 2>/dev/null | grep -qx flutter; then
    export FLUTTER_ROOT="$(asdf where flutter)"
  fi

  # # android path 追加
  # export PATH=$PATH:/Users/apple/Library/Android/sdk/platform-tools

  # 以下は入っている機械でだけ効く。無ければ何もしない (macos/chunks で入れるもの / 手で入れるもの)
  # openjdk (macos/chunks/flutter)。`brew --prefix` を毎回呼ぶと起動が遅くなるのでパスは決め打ち
  [ -d /opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home ] && export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
  # uv (Python)。installer が置く env を読む
  [ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
  # maestro (モバイル E2E)
  [ -d "$HOME/.maestro/bin" ] && export PATH="$PATH:$HOME/.maestro/bin"
  # ntn (Notion CLI, macos/chunks/notion)。公式 script が ~/.local/bin に置く。uv の env が無い機械でも通るように
  [ -x "$HOME/.local/bin/ntn" ] && case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$PATH:$HOME/.local/bin" ;; esac
# }}} バージョン管理ツールの読み込み ここまで

# コマンド追加 ここから {{{

  # 補完と入力候補 (macos/chunks/zsh で入る。入っていない機械では何もしない)
  # zsh-completions: 補完定義を fpath に足してから compinit を呼ぶ順序が必須
  [ -d /opt/homebrew/share/zsh-completions ] && fpath=(/opt/homebrew/share/zsh-completions $fpath)
  autoload -Uz compinit && compinit
  # zsh-autosuggestions: 履歴からの入力候補を薄く出す。→ で採用
  [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

  # fzf 読み込み
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

  # キーバインドは表で管理する (zsh/keybindings.conf)。widget は zsh/widgets/ に 1 関数 1 ファイル。
  # fzf 付属の widget (^T ^R Alt+C Tab) も同じ表で on/off できるので、fzf より後に読む。
  # 操作: keybind list / on / off / edit。この機械だけの変更は ~/.zsh-keybindings.local に落ちる。
  source "${${(%):-%N}:A:h}/zsh/keybindings.zsh"

  # Claude Code の自作サブコマンド。`ccx <サブコマンド>` の形で育てる。
  # cc は C コンパイラ (/usr/bin/cc) なので避けて ccx にした。
  function ccx() {
    case "$1" in
      # バックグラウンドセッション (claude --bg) の ID・名前・状態を一覧する。ID は claude attach / stop に渡す
      ls) claude agents --json | jq -r '.[] | select(.kind=="background") | [.id, .name, .state] | @tsv' ;;
      # 8 時間アイドルで daemon に退役させられたセッションを起こし直す。会話はそのまま戻る。
      # 引数なしなら退役中 (プロセスが無く、stop したものではない) を fzf で選ぶ。Tab で複数選択
      up)
        shift
        local ids=("$@")
        if (( ! $#ids )); then
          ids=(${(f)"$(claude agents --json --all \
            | jq -r '.[] | select(.kind=="background" and .pid==null and .state!="stopped") | [.id, .name, .state] | @tsv' \
            | fzf -m --with-nth=2.. --delimiter='\t' --prompt='起こす> ' | cut -f1)"})
        fi
        local id; for id in $ids; do claude respawn "$id"; done ;;
      *)  echo "usage: ccx ls | ccx up [id...]" >&2; return 1 ;;
    esac
  }

  # TOMATOMATO ゲームを開始する. ユーザーは早口で emoji を読んで下さい.
  function tomatomato() {

    # 稀にトマトクラッシュを起こすようにする.
    if [ $RANDOM = "777" ]; then
        for _ in `seq 0 1000`; do
          echo -n 🍅
          sleep 0.01
        done
        echo "\nあなたはラッキーです! 無事 1000 個のトマトが表示されました!"
        sleep 7
        return
    fi

    POTETO_NUM=1
    display=''
    for _ in `seq 0 $(($RANDOM % 10))`; do
      i=$(($RANDOM % 41 + 1))
      if [ $i = 41 ] && [ $POTETO_NUM = 1 ]; then
        POTETO_NUM=0
        display="${display}🥔"
      else
        case $(($RANDOM % 4)) in
          0 ) display="${display}🍅";;
          1 ) display="${display}🎯";;
          2 ) display="${display}👿";;
          3 ) display="${display}🚪";;
        esac
      fi
    done
    echo $display
    sleep 1
  }

# }}} コマンド追加 ここまで

# zsh 終了時に呼び出す関数を登録する ここから {{{
  # 参考は(こちら)[https://qiita.com/mollifier/items/558712f1a93ee07e22e2#zshexit]
  # tomatomato の自動呼び出しは外した。終了のたびに sleep 1 が入るため、
  # エージェントやスクリプトが短命な zsh を大量に起動すると 1 回 1 秒の税になる。
  # 遊びたいときは手で `tomatomato` と打つ。
# }}}  zsh 終了時に呼び出す関数を登録する ここまで

# プロンプト ここから {{{
  # 見た目は starship (macos/chunks/zsh で入る) に任せる。定義は zsh/starship.toml。
  # 入っていない機械では macOS 既定の `user@host dir %` のまま (何も壊れない)。
  # 公式の案内どおり .zshrc の末尾で init する: https://starship.rs/guide/
  if command -v starship >/dev/null; then
    export STARSHIP_CONFIG="${${(%):-%N}:A:h}/zsh/starship.toml"
    eval "$(starship init zsh)"
  fi
# }}} プロンプト ここまで

# パフォーマンス計測 終了
[ $ENABLE_PERFORMANCE_MEASUREMENT = 'TRUE' ] && zprof

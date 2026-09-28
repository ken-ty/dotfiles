# windows/Microsoft.PowerShell_profile.ps1
#
# macOS の .zshrc にある fzf 連携 (Ctrl+] でリポジトリ移動 / Ctrl+r で履歴検索) を
# Windows の PowerShell へ移したもの。
#
# install.ps1 が $PROFILE に「このファイルを dot-source する 1 行」を書き込む。
# symlink を張らない方針でも、リポジトリ側を直した時点で反映される。
#
# NOTE: 非 ASCII を含むので **UTF-8 BOM 付きで保存すること**。
#       PowerShell 5.1 は BOM 無しを ANSI (CP932) として読むため、BOM を落とすと
#       コメントが化けて構文エラーになる。PowerShell 7 では不要。

# ---------------------------------------------
# 文字コード
# ---------------------------------------------
# **PowerShell 5.1 の $OutputEncoding の既定は ASCIIEncoding。** ネイティブコマンド
# 同士をパイプすると PowerShell が間で文字列を再エンコードするため、非 ASCII が
# すべて "?" に潰れる。表示が崩れるだけではない ── 読んで書き戻す経路に乗せると
# **データが壊れる**:
#
#   bw list items --search x | jq -r $jq        ->  secret/...  ????
#   bw get item $id | jq ... | bw edit item $id ->  notes の日本語が ??? で保存される
#
# BOM 無しを明示するのが要点。[System.Text.Encoding]::UTF8 は preamble を持つので、
# ネイティブコマンドの stdin 先頭に BOM (U+FEFF) が載り、受け側の JSON.parse が落ちる。
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# 受け取り側 ── ネイティブコマンドの stdout をどう解釈するか。
# このマシンのコンソールは既に 65001 だが、**システム ACP は 932** なので、別の
# ターミナルや別マシンでは 932 で開きうる。そこで明示しておく。
# 代償として CP932 で出力する旧いツールの日本語は化けるが、開発ツール
# (git / gh / bw / jq / node) はすべて UTF-8 なのでこちらを取る。
#
# コンソールを持たないホストでは throw するので、profile 全体を止めないよう握る。
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

# ---------------------------------------------
# ghq + fzf
# ---------------------------------------------
# ghq list -p はバックスラッシュ区切りで返すが、Set-Location はそのまま受ける。
function Set-GhqLocation {
    $dir = ghq list -p | fzf
    if ($dir) { Set-Location $dir }
}
Set-Alias g Set-GhqLocation

# `if (Get-Module PSReadLine)` はガードにならない。profile が走る時点で PSReadLine は
# まだ読み込まれておらず、条件が常に偽になって binding が既定のまま残る。
# Get-Command ならコマンド探索で自動読み込みが走るので、ここで確実に載る。
if ($Host.Name -eq 'ConsoleHost' -and
    (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue)) {

    # Ctrl+] で ghq のリポジトリを絞り込んで移動。既定の GotoBrace を上書きする。
    # 届かないターミナル設定もある。反応しなければ chord を変えるか、alias の g で運用する。
    Set-PSReadLineKeyHandler -Chord 'Ctrl+]' -ScriptBlock {
        $dir = ghq list -p | fzf
        if ($dir) { Set-Location $dir }
        # fzf が画面を書き潰したあとのプロンプト再描画。省くと表示が崩れる。
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }

    # Ctrl+r で履歴の fuzzy search (.zshrc の fzf-select-history 相当)。
    # PSFzf は fzf が PATH に無いと Import-Module 自体が terminating error になり、
    # シェルを開くたびに例外が出る。fzf の存在も条件に入れる。
    if ((Get-Command fzf -ErrorAction SilentlyContinue) -and
        (Get-Module PSFzf -ListAvailable)) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}

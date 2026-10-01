# install.ps1
#
# Windows 用のブートストラップ。install.sh (Mac / Ubuntu) の対応物。
#
#   powershell -ExecutionPolicy Bypass -File windows\install.ps1
#
# 「git を入れる」から「Claude Code でスキルが有効になる」までを一本で通す。
# 2026-08-08 に Windows 11 で実際に踏んだ手順と地雷を、そのまま写したもの。
# 背景と詰まりどころは my-windows-setup スキルにある。
#
# install.sh との違いは意図的:
#
#   - **設定ファイルの symlink は張らない。** Windows は symlink 作成に特権を要求するし、
#     .zshrc は Windows で使わない。PowerShell profile だけは、$PROFILE に
#     dot-source の 1 行を追記することで symlink 相当の「直せば即反映」を得ている
#   - バックアップも作らない。触るのは git config と $PROFILE への 1 行追記だけ
#
# install.sh との共通化はまだしていない。まず Windows 単独で動くものを置く。
#
# 冪等。何度実行しても、既に済んでいるものは飛ばす。
#
# NOTE: このファイルは非 ASCII を含むので **UTF-8 BOM 付きで保存すること**。
#       PowerShell 5.1 は BOM 無しを ANSI (CP932) として読むため、BOM を落とすと
#       コメントが化けて構文エラーになる。
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    Write-Error "install.ps1 is for Windows. Use install.sh instead."
    exit 1
}

function Test-Has([string]$name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Confirm-Step([string]$what) {
    $ans = Read-Host "Do you want to setup $what? [y/N]"
    return $ans -match '^[yY]'
}

function Sync-Path {
    # winget も agent-skills の install.ps1 も PATH を「新しいターミナル向けに」書く。
    # 同じセッションで続けて使うには読み直しが要る。
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Invoke-Native([scriptblock]$block) {
    # $ErrorActionPreference='Stop' の下でネイティブ exe の stderr を 2>&1 すると、
    # PS 5.1 は 1 行ごとに終了エラーを投げる。ssh -T git@github.com は成功しても
    # stderr に書いて exit 1 を返すので、正常系でスクリプトが死ぬ。
    # gh auth status も未ログイン時に同じことをする。ここだけ緩める。
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $block 2>&1 | ForEach-Object { "    $_" } }
    finally { $ErrorActionPreference = $prev }
}

function Get-PersistedExecutionPolicy {
    # Process スコープを除いた実効ポリシー。install.ps1 は -ExecutionPolicy Bypass で
    # 起動するので Get-ExecutionPolicy をそのまま呼ぶと常に Bypass に見え、
    # 「$PROFILE が読み込まれない」状態を検出できない。
    foreach ($scope in 'MachinePolicy', 'UserPolicy', 'CurrentUser', 'LocalMachine') {
        $p = Get-ExecutionPolicy -Scope $scope
        if ($p -ne 'Undefined') { return $p }
    }
    return 'Restricted'   # すべて未定義なら Windows クライアントの既定
}

function Test-SymlinkPrivilege {
    # 実際に 1 本張ってみる以外に確実な判定は無い。開発者モード ON でも、昇格済みでも、
    # どちらでも通る ── 「いま symlink を張れるか」だけを見たいのでこれでよい。
    $probe = Join-Path $env:TEMP ("symprobe-" + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType SymbolicLink -Path $probe -Target $env:TEMP -ErrorAction Stop | Out-Null
        [System.IO.Directory]::Delete($probe, $false)   # リンクだけ消す（実体を辿らない）
        return $true
    } catch {
        return $false
    }
}

function Test-SudoUsable {
    if (-not (Test-Has 'sudo')) { return $false }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        sudo config 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } finally { $ErrorActionPreference = $prev }
}

function Show-PrivilegeHowTo {
    Write-Host ""
    Write-Host "  symlink を張る権限がありません。どちらか一方をやってください。"
    Write-Host ""
    Write-Host "  [A] 開発者モード (一度きり。以後なにも要らない)"
    Write-Host "        start ms-settings:developers"
    Write-Host "      -> 「開発者モード」を ON"
    Write-Host ""
    Write-Host "  [B] sudo (都度 UAC。管理者 PowerShell を開いて有効化する)"
    Write-Host "        Start-Process powershell -Verb RunAs"
    Write-Host "      -> 開いた窓で:"
    Write-Host "        sudo config --enable normal"
    Write-Host ""
    Write-Host "  どちらか済ませたら、このスクリプトを開き直して再実行してください。"
}

function Install-WinGet([string]$id, [string]$cmd, [string]$label) {
    if ($cmd -and (Test-Has $cmd)) {
        Write-Host "  ok      $label (already installed)"
        return
    }
    Write-Host "  install $label ($id)"
    winget install --id $id -e --accept-package-agreements --accept-source-agreements --disable-interactivity
    Sync-Path
}

# -----------------------------------------------
# Step 1: ツール
# -----------------------------------------------
Write-Host "==================================="
Write-Host "Step 1: Installing tools"
Write-Host "==================================="
Install-WinGet 'Git.Git'       'git'  'Git'
Install-WinGet 'GitHub.cli'    'gh'   'GitHub CLI'
Install-WinGet 'x-motemen.ghq' 'ghq'  'ghq'
Install-WinGet 'OpenJS.NodeJS' 'node' 'Node.js'
Install-WinGet 'junegunn.fzf'  'fzf'  'fzf'
Sync-Path

# -----------------------------------------------
# Step 2: アプリ
# -----------------------------------------------
Write-Host ""
Write-Host "==================================="
Write-Host "Step 2: Installing apps"
Write-Host "==================================="
# CLI が無いので Test-Has で判定できない。既存かどうかは winget が見て飛ばす。
if (Confirm-Step "Discord") {
    Install-WinGet 'Discord.Discord' $null 'Discord'
}

# -----------------------------------------------
# Step 3: git config
# -----------------------------------------------
Write-Host ""
Write-Host "==================================="
Write-Host "Step 3: git config"
Write-Host "==================================="

# これが Windows で最も効く 1 行。Git 同梱の MSYS 版 ssh は HOME のパス変換に失敗し、
# ユーザ名に非 ASCII が入っていると ~/.ssh を見失う。症状は publickey 拒否なので、
# 鍵や GitHub 側の登録を疑って延々はまる。Windows 標準の OpenSSH は USERPROFILE を
# 読むので影響を受けない。
$winSsh = "$env:SystemRoot\System32\OpenSSH\ssh.exe"
$currentSsh = (git config --global core.sshCommand)
if ($currentSsh) {
    Write-Host "  ok      core.sshCommand already set: $currentSsh"
} elseif (-not (Test-Path $winSsh)) {
    Write-Warning "  Windows OpenSSH not found at $winSsh - skipping core.sshCommand"
} else {
    git config --global core.sshCommand ($winSsh -replace '\\', '/')
    Write-Host "  set     core.sshCommand -> Windows OpenSSH"
}

if (git config --global init.defaultBranch) {
    Write-Host "  ok      init.defaultBranch already set"
} else {
    git config --global init.defaultBranch main
    Write-Host "  set     init.defaultBranch=main"
}

# -----------------------------------------------
# Step 4: SSH 鍵
# -----------------------------------------------
Write-Host ""
Write-Host "==================================="
Write-Host "Step 4: SSH key"
Write-Host "==================================="
$sshDir = Join-Path $env:USERPROFILE '.ssh'
$key = Join-Path $sshDir 'id_ed25519'
if (Test-Path $key) {
    Write-Host "  ok      $key already exists"
} elseif (Confirm-Step "an ed25519 SSH key") {
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
    $email = Read-Host "  email for the key comment"
    # 引数を 1 本の文字列にして Start-Process に渡す。ssh-keygen を直に呼ぶと
    # PowerShell がネイティブ exe への空文字引数を落とすので -N "" が消え、
    # 「パスフレーズ無しのつもりが無しになっていない」鍵ができる。しかも成功して見える。
    Start-Process ssh-keygen -Wait -NoNewWindow -ArgumentList `
        "-t ed25519 -C `"$email`" -f `"$key`" -N `"`" -q"
    $check = Start-Process ssh-keygen -Wait -NoNewWindow -PassThru -ArgumentList "-y -f `"$key`" -P `"`""
    if ($check.ExitCode -ne 0) {
        Write-Error "  key was created but is not passphrase-less - remove it and retry"
        exit 1
    }
    Write-Host "  created $key (no passphrase)"
}

if (Test-Path "$key.pub") {
    $pub = Get-Content "$key.pub"
    Write-Host ""
    Write-Host "  Register this public key: https://github.com/settings/ssh/new"
    Write-Host ""
    Write-Host "    $pub"
    Write-Host ""
    Read-Host "  Press Enter once it is registered (or to skip)" | Out-Null
    Write-Host "  verifying..."
    Invoke-Native { ssh -o StrictHostKeyChecking=accept-new -T git@github.com }
}

# -----------------------------------------------
# Step 5: gh 認証
# -----------------------------------------------
Write-Host ""
Write-Host "==================================="
Write-Host "Step 5: gh auth"
Write-Host "==================================="
# ブラウザ対話なので自動化できない。状態だけ見て、必要なら人に渡す。
Invoke-Native { gh auth status }
Write-Host "  If not logged in:  gh auth login"
Write-Host "  (GitHub.com -> SSH -> Skip key upload -> Login with a web browser)"

# -----------------------------------------------
# Step 6: agent-skills
# -----------------------------------------------
Write-Host ""
Write-Host "==================================="
Write-Host "Step 6: agent-skills"
Write-Host "==================================="
# ai-skills ではなく agent-skills。ツール (agent-skills) とデータ (agent-skills-store) が
# 別リポジトリに分かれている。
if (Confirm-Step "agent-skills (skills for Claude Code and friends)") {
    if (-not (Test-Has 'ghq')) {
        Write-Warning "  ghq not on PATH yet - reopen the terminal and re-run"
    } else {
        ghq get -p ken-ty/agent-skills
        ghq get -p ken-ty/agent-skills-store
        $root  = (ghq root)
        $tool  = Join-Path $root 'github.com\ken-ty\agent-skills'
        $store = Join-Path $root 'github.com\ken-ty\agent-skills-store'

        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tool 'install.ps1')
        Sync-Path
        $env:AGENT_SKILLS_HOME = [Environment]::GetEnvironmentVariable('AGENT_SKILLS_HOME', 'User')

        # link / sync は symlink を作るので特権が要る。EPERM を踏んでから案内するのでは
        # 「途中まで進んで止まった」状態になるので、張る前に判定して打つべきコマンドを出す。
        Write-Host ""
        if (Test-SymlinkPrivilege) {
            Write-Host "  wiring the store"
            & agent-skills link $store
            & agent-skills sync
        } elseif (Test-SudoUsable) {
            Write-Host "  wiring the store via sudo (UAC will prompt)"
            & sudo agent-skills link $store
            & sudo agent-skills sync
        } else {
            Write-Host "  skipped: cannot create symlinks yet."
            Show-PrivilegeHowTo
            Write-Host ""
            Write-Host "  再実行後は、この 2 つだけで済みます:"
            Write-Host "    agent-skills link `"$store`""
            Write-Host "    agent-skills sync"
        }
    }
}

# -----------------------------------------------
# Step 7: PowerShell profile
# -----------------------------------------------
Write-Host ""
Write-Host "==================================="
Write-Host "Step 7: PowerShell profile"
Write-Host "==================================="
# symlink は張らない方針なので、$PROFILE には「リポジトリ側を dot-source する 1 行」だけを
# 置く。コピーと違い、リポジトリを直した時点で反映され、再実行が要らない。
# 既存の $PROFILE は上書きせず追記する。
$profileSrc = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'
if (-not (Test-Path $profileSrc)) {
    Write-Warning "  not found: $profileSrc"
} else {
    $line     = ". `"$profileSrc`""
    $existing = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { '' }
    if ($existing -and $existing.Contains($line)) {
        Write-Host "  ok      `$PROFILE already sources the repo profile"
    } else {
        $profileDir = Split-Path $PROFILE -Parent
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        Add-Content -Path $PROFILE -Value $line -Encoding UTF8
        Write-Host "  wired   `$PROFILE -> $profileSrc"
    }
    Write-Host "  `$PROFILE = $PROFILE"

    # 配線しただけでは足りない。ExecutionPolicy が Restricted だと $PROFILE は
    # 読み込まれず、しかも install.ps1 自身は Bypass で動くので気付けない。
    # 「入れたのに次回以降ずっと無効」になるので、ここで必ず検査する。
    # 2026-09-23 に Windows 11 で実際に踏んだ。
    $ep = Get-PersistedExecutionPolicy
    if ($ep -in @('Restricted', 'AllSigned')) {
        Write-Host ""
        Write-Warning "  ExecutionPolicy is $ep - `$PROFILE will NOT be loaded."
        Write-Host ""
        Write-Host "  Run this yourself (no admin needed):"
        Write-Host "    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned"
        Write-Host ""
        Write-Host "  Then open a NEW terminal. Already-open shells keep the old policy."
    } else {
        Write-Host "  ok      ExecutionPolicy = $ep"
    }
}

# -----------------------------------------------
# Step 8: PSFzf
# -----------------------------------------------
Write-Host ""
Write-Host "==================================="
Write-Host "Step 8: PSFzf (Ctrl+r history search)"
Write-Host "==================================="
# Ctrl+] (ghq 移動) は profile だけで足りる。Ctrl+r の履歴検索にはこのモジュールが要る。
# 未導入でも profile は静かに飛ばすので、入れなくても壊れない。
if (Get-Module PSFzf -ListAvailable) {
    Write-Host "  ok      PSFzf already installed"
} elseif (Confirm-Step "PSFzf (fuzzy history search on Ctrl+r)") {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
    # PSGallery が Untrusted だと確認プロンプトが出る。一時的に信頼して、必ず戻す。
    $policy = (Get-PSRepository -Name PSGallery).InstallationPolicy
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    try {
        Install-Module PSFzf -Scope CurrentUser -Force -AllowClobber
        Write-Host "  installed PSFzf"
    } finally {
        Set-PSRepository -Name PSGallery -InstallationPolicy $policy
    }
}

# -----------------------------------------------
# 残り
# -----------------------------------------------
Write-Host ""
Write-Host "==================================="
Write-Host "Remaining manual steps"
Write-Host "==================================="
Write-Host "These need a browser or a system setting - they cannot be scripted."
Write-Host ""
Write-Host "  1. gh auth login                 # if Step 5 said you are not logged in"
Write-Host "  2. Symlink privilege - only if Step 6 told you so. It prints the commands."
Write-Host "  3. Reopen the terminal, then check the fzf bindings:"
Write-Host "       fzf --version"
Write-Host "       g          # ghq repo picker"
Write-Host "       Ctrl+]     # same, as a key binding"
Write-Host "       Ctrl+r     # history search (needs Step 8)"
Write-Host "     Ctrl+] does not reach every terminal. If it is dead, use g or rebind it."
Write-Host ""

# 配布後のヘルスチェック (ADR 0011)。agent-skills doctor を案内するだけでなく実行する。
# ホームから流すと個人のスキルを project のものと取り違えるので、リポジトリの中 (この dotfiles) で流す。
# install.sh と違い、BAD でも install.ps1 は失敗にしない。Step 6 で symlink の権限が無く
# 飛ばした機械では BAD が出るのが想定どおりで、そこはこのスクリプトの外で直すものだから。
Write-Host "==================================="
Write-Host "Health check: agent-skills doctor"
Write-Host "==================================="
if (Test-Has 'agent-skills') {
    Push-Location (Split-Path $PSScriptRoot -Parent)
    try { Invoke-Native { agent-skills doctor } }
    finally { Pop-Location }
} else {
    Write-Host "  skipped: agent-skills is not on PATH (Step 6 skipped, or reopen the terminal)."
    Write-Host "  Later, from inside any repo (not from your home directory):"
    Write-Host "    agent-skills doctor"
}
Write-Host ""
Write-Host "Traps behind each step: the my-windows-setup skill."

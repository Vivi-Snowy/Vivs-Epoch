# =====================================================================
#  Viv's Epoch v1.0.0 - a DayZ Epoch server pack by Vivi Snowy
#  https://github.com/Vivi-Snowy   |   https://ko-fi.com/vivienne38
#
#  One-click installer (started by INSTALL.bat). It:
#    1. checks Arma 2, Operation Arrowhead and the DayZ Epoch files are in place
#    2. installs the Visual C++ runtimes that came with the Epoch server files
#    3. installs MariaDB (the free database the server saves to), if you don't have it
#    4. creates the dayz_epoch database with its own random passwords
#    5. unpacks the Lingor map files from your Downloads folder (if you want Lingor)
#    6. adds START and PLAY shortcuts to your Steam library
#  Safe to run again: anything already done is skipped.
# =====================================================================
$ErrorActionPreference = 'Continue'
$Game     = Split-Path -Parent $PSScriptRoot
$Cfg      = Join-Path $Game 'DZE_Server_Config'
$Log      = Join-Path $Game 'INSTALL_LOG.txt'
$Dl       = Join-Path $env:USERPROFILE 'Downloads'
$MariaVer = '10.11.19'
$MsiName  = "mariadb-$MariaVer-winx64.msi"
$MsiUrls  = @("https://archive.mariadb.org/mariadb-$MariaVer/winx64-packages/$MsiName")
$DbPort   = 3316        # a quiet port, so it doesn't clash with other database programs
Start-Transcript -Path $Log -Force | Out-Null
$problems = @()
$notes    = @()

function Step($t) { Write-Host ""; Write-Host "==== $t ====" -ForegroundColor Cyan }
function New-Password { $c = (48..57) + (65..90) + (97..122); -join (1..16 | ForEach-Object { [char]($c | Get-Random) }) }
function Finish {
    Write-Host ""
    if ($problems.Count -eq 0) {
        Write-Host "All done!" -ForegroundColor Green
    } else {
        Write-Host "Not finished yet - please sort these out, then run INSTALL.bat again:" -ForegroundColor Yellow
        $problems | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    if ($notes.Count) { Write-Host ""; $notes | ForEach-Object { Write-Host "  $_" } }
    Write-Host ""
    Write-Host "  Thanks for playing Viv's Epoch by Vivi Snowy!" -ForegroundColor Magenta
    Write-Host "  If you enjoy it, you can support me at https://ko-fi.com/vivienne38" -ForegroundColor Magenta
    Write-Host "  (A full log of this install is in INSTALL_LOG.txt.)"
    Stop-Transcript | Out-Null
    Read-Host "Press Enter to close"
    exit
}

Write-Host ""
Write-Host "  ================================================" -ForegroundColor Magenta
Write-Host "     Viv's Epoch v1.0.0  -  by Vivi Snowy" -ForegroundColor Magenta
Write-Host "     Chernarus + Lingor, offline / LAN, PvE" -ForegroundColor Magenta
Write-Host "  ================================================" -ForegroundColor Magenta
Write-Host "  Game folder: $Game"

# ---------------- 0. Is everything in place? ----------------
Step "1/7 Checking your game files"
if (-not (Test-Path (Join-Path $Game 'arma2oaserver.exe'))) {
    $problems += "These files must go inside your 'Arma 2 Operation Arrowhead' game folder (the one with ArmA2OA.exe). Right now they are in: $Game"
    Finish
}
$A2 = Join-Path (Split-Path -Parent $Game) 'Arma 2'
if (-not (Test-Path $A2)) {
    $problems += "Arma 2 (the original game) was not found next to Operation Arrowhead. Install 'Arma 2' from Steam into the same library: https://store.steampowered.com/app/33900/"
}
if (-not (Test-Path (Join-Path $Game '@DayZ_Epoch\addons'))) {
    $problems += "The DayZ Epoch 1.0.7.1 CLIENT files are missing (no @DayZ_Epoch folder). Download them from https://github.com/EpochModTeam/DayZ-Epoch/releases/tag/1.0.7.1 and extract them into: $Game"
}
# the Epoch server package keeps its DLLs in a 'dlls' subfolder - they have to sit next to arma2oaserver.exe
foreach ($d in 'HiveExt.dll','DatabaseMySql.dll','tbb.dll','tbbmalloc.dll') {
    $src = Join-Path $Game "dlls\$d"
    if (-not (Test-Path (Join-Path $Game $d)) -and (Test-Path $src)) { Copy-Item $src $Game; Write-Host "  copied $d from the Epoch dlls folder" }
}
if (-not (Test-Path (Join-Path $Game 'HiveExt.dll')) -or -not (Test-Path (Join-Path $Game 'DatabaseMySql.dll'))) {
    $problems += "The DayZ Epoch 1.0.7.1 SERVER files are missing (no HiveExt.dll / DatabaseMySql.dll). Download them from https://github.com/EpochModTeam/DayZ-Epoch/releases/tag/1.0.7.1 (archive password: 123456), copy everything inside its 'Server Files' folder into: $Game, then copy THESE files over the top again (say Yes to replace)."
}
if ($problems.Count) { Finish }
Write-Host "  Arma 2, Operation Arrowhead and DayZ Epoch found."

# ---------------- Lingor? ----------------
$LingorParts = @(@('lingor-1.5.7z','@lingor\addons'), @('ibr_plants-1.5.7z','@ibr_plants\addons'), @('brg_africa-1.23.7z','@brg_africa\addons'))
$lingorHave  = @($LingorParts | Where-Object { Test-Path (Join-Path $Game $_[1]) }).Count -eq 3
$lingorZips  = @($LingorParts | Where-Object { Test-Path (Join-Path $Dl $_[0]) }).Count -gt 0
$hasChern    = Test-Path (Join-Path $Game 'CHERNARUS_1_START_SERVER.bat')
$hasLingor   = Test-Path (Join-Path $Game 'LINGOR_1_START_SERVER.bat')
if (-not $hasChern -and -not $hasLingor) { $problems += "My server files are missing - copy everything from the release zip into: $Game"; Finish }
$wantLingor  = $hasLingor -and ($lingorHave -or $lingorZips -or -not $hasChern)
if ($hasLingor -and -not $wantLingor) {
    $a = Read-Host "  Do you also want the LINGOR map? It needs 3 extra downloads (about 310 MB). (Y/N)"
    $wantLingor = $a -match '^[Yy]'
}

# ---------------- 1. Visual C++ runtimes ----------------
Step "2/7 Visual C++ runtimes (needed by the database plugin)"
$vc = @('VC_Redist','Visual Studio C++ Redistributables') | ForEach-Object { Get-ChildItem (Join-Path $Game $_) -Filter *.exe -Recurse -ErrorAction SilentlyContinue } | Sort-Object FullName
if (-not $vc) { Write-Host "  The Epoch server files' Visual C++ folder wasn't found - skipping (most PCs already have these)." }
$vc | ForEach-Object {
    $a = if (($_.FullName -match 'VC201[57]') -or ($_.Name -match '^vc_redist|2015|2017')) { '/install /quiet /norestart' } else { '/q /norestart' }
    Write-Host "  $($_.Name)"
    Start-Process $_.FullName -ArgumentList $a -Wait
}

# ---------------- 2. MariaDB ----------------
Step "3/7 MariaDB database program"
$RootPwFile = Join-Path $Cfg 'mariadb_root_password.txt'
$mysql  = Get-ChildItem "$env:ProgramFiles\MariaDB*\bin\mysql.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
$RootPw = $null
if (-not $mysql) {
    $msi = @((Join-Path $PSScriptRoot $MsiName), (Join-Path $Dl $MsiName)) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $msi) {
        Write-Host "  MariaDB $MariaVer is not installed yet."
        Write-Host "  It is free, and about 85 MB. Source: $($MsiUrls[0])"
        $ans = Read-Host "  Download and install it now? (Y/N)"
        if ($ans -notmatch '^[Yy]') { $problems += "MariaDB is needed. Download $MsiName from https://mariadb.org/download/ into your Downloads folder and run INSTALL.bat again"; Finish }
        $msi = Join-Path $PSScriptRoot $MsiName
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        foreach ($u in $MsiUrls) {
            try {
                Write-Host "  downloading..."
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $u -OutFile $msi -UseBasicParsing -ErrorAction Stop
                if ((Get-Item $msi).Length -gt 20MB) { break }
            } catch { Write-Host "  failed: $($_.Exception.Message)" -ForegroundColor Yellow }
            Remove-Item $msi -ErrorAction SilentlyContinue
        }
        if (-not (Test-Path $msi)) { $problems += "Could not download MariaDB. Download $MsiName from https://mariadb.org/download/ into your Downloads folder and run INSTALL.bat again"; Finish }
    }
    $RootPw = New-Password
    Set-Content $RootPwFile $RootPw
    Write-Host "  installing MariaDB (1-2 minutes)..."
    $p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" SERVICENAME=MariaDB PORT=$DbPort PASSWORD=$RootPw UTF8=0 /qn /l*v `"$Cfg\mariadb_install.log`"" -Wait -PassThru
    Write-Host "  installer finished (code $($p.ExitCode))"
    $mysql = Get-ChildItem "$env:ProgramFiles\MariaDB*\bin\mysql.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $mysql) { $problems += "MariaDB did not install (details in DZE_Server_Config\mariadb_install.log)"; Finish }
} else {
    Write-Host "  already installed: $($mysql.FullName)"
    # use the port the existing install was set up with
    $ini = Get-ChildItem "$env:ProgramFiles\MariaDB*\data\my.ini" -ErrorAction SilentlyContinue | Select-Object -First 1
    $DbPort = 3306
    if ($ini) { $m = Select-String -Path $ini.FullName -Pattern '^\s*port\s*=\s*(\d+)' | Select-Object -First 1; if ($m) { $DbPort = [int]$m.Matches[0].Groups[1].Value } }
    Write-Host "  it uses port $DbPort"
    if (Test-Path $RootPwFile) { $RootPw = (Get-Content $RootPwFile -Raw).Trim() }
    else {
        $s = Read-Host "  Type the MariaDB 'root' password you chose when you installed it (leave empty if you never set one)" -AsSecureString
        $RootPw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
        if (-not $RootPw) { $RootPw = $null }
    }
}
Set-Service MariaDB -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service MariaDB -ErrorAction SilentlyContinue
Start-Sleep 3

# ---------------- 3. Passwords (made fresh on every PC) ----------------
Step "4/7 Setting up your passwords"
$DbPwFile = Join-Path $PSScriptRoot 'dbpw.txt'
if (Test-Path $DbPwFile) { $DbPw = (Get-Content $DbPwFile -Raw).Trim() } else { $DbPw = New-Password; Set-Content $DbPwFile $DbPw }
foreach ($c in @('DZE_Server_Config','DZE_Server_Config_Lingor')) {
    $hi = Join-Path $Game "$c\HiveExt.ini"
    if (Test-Path $hi) {
        $t = Get-Content $hi -Raw
        $t = $t -replace '(?m)^Port = \d+', "Port = $DbPort"
        $t = $t -replace '(?m)^Password = [^\r\n]*', "Password = $DbPw"
        Set-Content $hi $t -NoNewline
    }
}
$AdminFile = Join-Path $Game 'ADMIN_PASSWORD.txt'
if (Test-Path $AdminFile) { $AdminPw = ((Get-Content $AdminFile | Select-Object -First 1) -replace '^.*:\s*', '').Trim() } else { $AdminPw = New-Password }
foreach ($c in @('DZE_Server_Config','DZE_Server_Config_Lingor')) {
    $sc = Join-Path $Game "$c\server.cfg"
    if (Test-Path $sc) {
        $t = Get-Content $sc -Raw
        $n = $t -replace 'passwordAdmin = "SET_BY_INSTALLER";', "passwordAdmin = `"$AdminPw`";"
        if ($n -ne $t) { Set-Content $sc $n -NoNewline }
    }
}
if (-not (Test-Path $AdminFile)) {
    Set-Content $AdminFile @("Admin password: $AdminPw", "", "In game, open chat and type:  #login $AdminPw", "Keep this file private.")
}
Write-Host "  done - your in-game admin password is in ADMIN_PASSWORD.txt"

# ---------------- 4. Database ----------------
Step "5/7 Creating the DayZ Epoch database"
$M = $mysql.FullName
$rootArgs = @("--user=root","--host","127.0.0.1","--port=$DbPort"); if ($RootPw) { $rootArgs += "--password=$RootPw" }
$rootCmd  = if ($RootPw) { "-uroot -p$RootPw -h127.0.0.1 -P$DbPort" } else { "-uroot -h127.0.0.1 -P$DbPort" }
$sql = "CREATE DATABASE IF NOT EXISTS dayz_epoch; " +
       "CREATE USER IF NOT EXISTS 'dayz'@'localhost' IDENTIFIED BY '$DbPw'; CREATE USER IF NOT EXISTS 'dayz'@'127.0.0.1' IDENTIFIED BY '$DbPw'; " +
       "ALTER USER 'dayz'@'localhost' IDENTIFIED BY '$DbPw'; ALTER USER 'dayz'@'127.0.0.1' IDENTIFIED BY '$DbPw'; " +
       "GRANT ALL PRIVILEGES ON dayz_epoch.* TO 'dayz'@'localhost'; GRANT ALL PRIVILEGES ON dayz_epoch.* TO 'dayz'@'127.0.0.1'; " +
       "GRANT SUPER ON *.* TO 'dayz'@'localhost'; GRANT SUPER ON *.* TO 'dayz'@'127.0.0.1'; FLUSH PRIVILEGES; SET GLOBAL event_scheduler=ON;"
& $M @rootArgs -e $sql
if ($LASTEXITCODE -ne 0) {
    if (Test-Path $RootPwFile) { $problems += "Could not log in to MariaDB as root - the password in DZE_Server_Config\mariadb_root_password.txt doesn't match" }
    else { $problems += "Could not log in to MariaDB as root - wrong root password? Run INSTALL.bat again and type it carefully" }
    Finish
}
$tables = & $M @rootArgs -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='dayz_epoch';"
if ([int]$tables -lt 4) {
    Write-Host "  importing the Epoch tables..."
    cmd /c "`"$M`" $rootCmd dayz_epoch < `"$Cfg\SQL\epoch.sql`""
    cmd /c "`"$M`" $rootCmd dayz_epoch < `"$Cfg\SQL\add_recommended_mysql_events.sql`""
} else { Write-Host "  the database already has $tables tables - kept as it is (your saves are safe)" }
$t = & $M --user=dayz "--password=$DbPw" --host 127.0.0.1 "--port=$DbPort" dayz_epoch -N -e "SHOW TABLES;"
if ($LASTEXITCODE -ne 0) { $problems += "The server's database login does not work" } else { Write-Host "  OK - $(@($t).Count) tables, the server can log in" }
$myini = Get-ChildItem "$env:ProgramFiles\MariaDB*\data\my.ini" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($myini -and -not (Select-String -Path $myini.FullName -Pattern 'event_scheduler' -Quiet)) {
    (Get-Content $myini.FullName) -replace '^\[mysqld\]$', "[mysqld]`r`nevent_scheduler=ON" | Set-Content $myini.FullName
}

# ---------------- 5. Lingor map files ----------------
Step "6/7 Lingor map"
if (-not $wantLingor) {
    Write-Host "  skipped (Chernarus only). Run INSTALL.bat again any time to add Lingor."
} elseif ($lingorHave) {
    Write-Host "  Lingor map files already installed."
} else {
    $7z = @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $7z) {
        Write-Host "  7-Zip not found - installing it (free) with winget..."
        winget install --id 7zip.7zip -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
        $7z = @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
    $links = @{ 'lingor-1.5.7z'      = 'https://www.moddb.com/games/arma-2/addons/jungle-wars-island-of-lingor';
                'ibr_plants-1.5.7z'  = 'https://www.moddb.com/games/arma-2/addons/ibr-plants';
                'brg_africa-1.23.7z' = 'https://www.moddb.com/games/arma-2/addons/african-foliage' }
    foreach ($a in $LingorParts) {
        $zip = Join-Path $Dl $a[0]; $check = Join-Path $Game $a[1]
        if (Test-Path $check) { Write-Host "  $($a[0]) already installed"; continue }
        if (-not (Test-Path $zip)) { $problems += "Lingor needs $($a[0]) in your Downloads folder. Get it here: $($links[$a[0]])"; continue }
        if (-not $7z) { $problems += "7-Zip is needed to unpack $($a[0]). Install it from https://www.7-zip.org/"; continue }
        Write-Host "  unpacking $($a[0])..."
        & $7z x $zip "-o$Game" -y | Out-Null
        if (Test-Path $check) { Write-Host "    OK" } else { $problems += "Could not unpack $($a[0]) - is the download complete?" }
    }
}

# ---------------- 6. Unblock + desktop shortcuts ----------------
Step "7/7 Shortcuts in Steam"
Get-ChildItem $Game -Filter *.dll | Unblock-File
foreach ($d in @('@DayZ_Epoch_Server','@DayZ_Epoch_Server_Lingor','@lingor','@ibr_plants','@brg_africa','setup')) {
    Get-ChildItem (Join-Path $Game $d) -Recurse -File -ErrorAction SilentlyContinue | Unblock-File
}
Get-ChildItem $Game -Filter *.bat | Unblock-File

# what to add: the server starts through PowerShell (the auto-restart watcher), the game starts ArmA2OA.exe directly
$PsExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$OaExe = Join-Path $Game 'ArmA2OA.exe'
$lingorReady = @($LingorParts | Where-Object { Test-Path (Join-Path $Game $_[1]) }).Count -eq 3
$defs = @()
if ($hasChern) {
    $defs += ,@('DayZ Chernarus - 1 START SERVER', $PsExe, "-NoProfile -ExecutionPolicy Bypass -File `"$Game\setup\server_loop.ps1`"", 'CHERNARUS_1_START_SERVER.bat')
    $defs += ,@('DayZ Chernarus - 2 PLAY', $OaExe, "`"-mod=$A2;EXPANSION;ca;@DayZ_Epoch`" -nosplash -skipIntro -world=empty -connect=127.0.0.1 -port=2302", 'CHERNARUS_2_PLAY.bat')
}
if ($wantLingor -and $lingorReady) {
    $defs += ,@('DayZ Lingor - 1 START SERVER', $PsExe, "-NoProfile -ExecutionPolicy Bypass -File `"$Game\setup\server_loop_lingor.ps1`"", 'LINGOR_1_START_SERVER.bat')
    $defs += ,@('DayZ Lingor - 2 PLAY', $OaExe, "`"-mod=$A2;EXPANSION;ca;@lingor;@ibr_plants;@brg_africa;@DayZ_Epoch`" -nosplash -skipIntro -world=empty -connect=127.0.0.1 -port=2402", 'LINGOR_2_PLAY.bat')
}

function Get-Crc32([byte[]]$bytes) {
    $crc = 0xFFFFFFFFL
    foreach ($x in $bytes) {
        $crc = $crc -bxor [long]$x
        for ($k = 0; $k -lt 8; $k++) { if ($crc -band 1L) { $crc = ($crc -shr 1) -bxor 0xEDB88320L } else { $crc = $crc -shr 1 } }
    }
    return (($crc -bxor 0xFFFFFFFFL) -band 0xFFFFFFFFL)
}
# reads Steam's binary shortcuts.vdf just enough to count the entries and see their names
function Read-Shortcuts([byte[]]$b) {
    $script:vp = 0; $script:vCount = 0; $script:vNames = @()
    function Read-Str { $s = $script:vp; while ($b[$script:vp] -ne 0) { $script:vp++ }; $r = [Text.Encoding]::UTF8.GetString($b, $s, $script:vp - $s); $script:vp++; $r }
    function Read-Map([int]$depth) {
        while ($true) {
            $t = $b[$script:vp]; $script:vp++
            if ($t -eq 8) { return }
            $key = Read-Str
            if ($depth -eq 1) { $script:vCount++ }
            if ($t -eq 0) { Read-Map ($depth + 1) }
            elseif ($t -eq 1) { $val = Read-Str; if ($depth -eq 2 -and $key -ieq 'AppName') { $script:vNames += $val } }
            elseif ($t -eq 2) { $script:vp += 4 }
            else { throw "unexpected value type $t" }
        }
    }
    Read-Map 0
}

$enc = [Text.Encoding]::UTF8
$steamDir = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
if ($steamDir) { $steamDir = $steamDir -replace '/', '\' }
$steamExe = if ($steamDir) { Join-Path $steamDir 'steam.exe' } else { $null }
$users = @()
if ($steamExe -and (Test-Path $steamExe)) { $users = @(Get-ChildItem (Join-Path $steamDir 'userdata') -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+$' -and $_.Name -ne '0' }) }
$addedSteam = $false
if (-not $users.Count) {
    Write-Host "  Steam (with a logged-in account) wasn't found - making desktop shortcuts instead." -ForegroundColor Yellow
} else {
    $steamWasRunning = [bool](Get-Process steam -ErrorAction SilentlyContinue)
    $go = $true
    if ($steamWasRunning) {
        $a = Read-Host "  Steam has to close for a few seconds so the shortcuts can be added. Close Steam now? (Y/N)"
        if ($a -match '^[Yy]') {
            & $steamExe -shutdown
            for ($i = 0; $i -lt 60 -and (Get-Process steam -ErrorAction SilentlyContinue); $i++) { Start-Sleep 1 }
            Start-Sleep 3
            if (Get-Process steam -ErrorAction SilentlyContinue) { $go = $false; Write-Host "  Steam didn't close - making desktop shortcuts instead." -ForegroundColor Yellow }
        } else { $go = $false; Write-Host "  OK - making desktop shortcuts instead." }
    }
    if ($go) {
        foreach ($u in $users) {
            try {
                $cfgDir = Join-Path $u.FullName 'config'
                New-Item -ItemType Directory -Force $cfgDir | Out-Null
                $vdf = Join-Path $cfgDir 'shortcuts.vdf'
                if ((Test-Path $vdf) -and (Get-Item $vdf).Length -gt 2) {
                    [byte[]]$old = [IO.File]::ReadAllBytes($vdf)
                    if ($old[$old.Length - 1] -ne 8 -or $old[$old.Length - 2] -ne 8) { throw "the shortcut list looks unusual - left it alone" }
                    Read-Shortcuts $old
                    Copy-Item $vdf "$vdf.bak_before_dayz_epoch_servers" -Force
                    $head = $old[0..($old.Length - 3)]
                } else {
                    $script:vCount = 0; $script:vNames = @()
                    $head = @(0) + $enc.GetBytes('shortcuts') + @(0)
                }
                $buf = New-Object System.Collections.Generic.List[byte]
                $buf.AddRange([byte[]]$head)
                $n = $script:vCount; $added = 0
                foreach ($d in $defs) {
                    if ($script:vNames -contains $d[0]) { Write-Host "  account $($u.Name): '$($d[0])' already there"; continue }
                    $exeQ = "`"$($d[1])`""
                    $appid = [uint32]((Get-Crc32 ($enc.GetBytes($exeQ + $d[0]))) -bor 0x80000000L)
                    $buf.Add(0); $buf.AddRange($enc.GetBytes("$n")); $buf.Add(0)
                    $buf.Add(2); $buf.AddRange($enc.GetBytes('appid')); $buf.Add(0); $buf.AddRange([BitConverter]::GetBytes($appid))
                    foreach ($kv in @(@('AppName', $d[0]), @('Exe', $exeQ), @('StartDir', "$Game\"), @('icon', $OaExe), @('ShortcutPath', ''), @('LaunchOptions', $d[2]))) {
                        $buf.Add(1); $buf.AddRange($enc.GetBytes($kv[0])); $buf.Add(0); $buf.AddRange($enc.GetBytes($kv[1])); $buf.Add(0)
                    }
                    foreach ($kv in @(@('IsHidden', 0), @('AllowDesktopConfig', 1), @('AllowOverlay', 1), @('OpenVR', 0), @('Devkit', 0))) {
                        $buf.Add(2); $buf.AddRange($enc.GetBytes($kv[0])); $buf.Add(0); $buf.AddRange([BitConverter]::GetBytes([uint32]$kv[1]))
                    }
                    $buf.Add(0); $buf.AddRange($enc.GetBytes('tags')); $buf.Add(0); $buf.Add(8)
                    $buf.Add(8)
                    $n++; $added++
                }
                $buf.Add(8); $buf.Add(8)
                [IO.File]::WriteAllBytes($vdf, $buf.ToArray())
                Write-Host "  account $($u.Name): added $added shortcut(s) to your Steam library"
                $addedSteam = $true
            } catch { Write-Host "  account $($u.Name): $($_.Exception.Message)" -ForegroundColor Yellow }
        }
        # start Steam again as you (not as administrator), so the game and server can talk to it
        if ($steamWasRunning) { Start-Process explorer.exe -ArgumentList "`"$steamExe`""; Write-Host "  Steam is starting again" }
    }
}
if (-not $addedSteam) {
    $desk = [Environment]::GetFolderPath('Desktop')
    $ws = New-Object -ComObject WScript.Shell
    foreach ($d in $defs) {
        $l = $ws.CreateShortcut((Join-Path $desk "$($d[0]).lnk"))
        $l.TargetPath = Join-Path $Game $d[3]
        $l.WorkingDirectory = $Game
        $l.IconLocation = $OaExe + ',0'
        $l.Save()
        Write-Host "  desktop: $($d[0])"
    }
}
foreach ($d in $defs) { Write-Host "  - $($d[0])" }

$where = if ($addedSteam) { 'in your Steam library' } else { 'on your desktop' }
$notes += "HOW TO PLAY: make sure Steam is running, start '1 START SERVER' $where,"
$notes += "wait 1-2 minutes, then start '2 PLAY'. Full guide: README.md"
Finish

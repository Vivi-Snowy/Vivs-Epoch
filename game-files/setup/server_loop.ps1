# DayZ Epoch server watcher - keeps the Chernarus server running and restarts it on schedule.
# How restarts work:
#   - The server counts down 90 minutes from when the mission starts (first player joins), warns players
#     in chat at 30/15/5/2/1 minutes, saves everyone and writes DZ_RESTART_NOW to its log.
#   - This script sees that line, closes the server and starts a fresh one (installing any *.pbo.new updates).
#   - The server writes a "DZ RESTART: heartbeat" line every 5 minutes. If the mission is running and no
#     heartbeat shows up for 12 minutes, the server has frozen and is restarted.
#   - If the server crashes or is closed, it is started again after 15 seconds.
#   - Only one watcher can run at a time, and any old server left running is closed first.
$ErrorActionPreference = 'Continue'
$Game = Split-Path -Parent $PSScriptRoot
$A2   = (Resolve-Path (Join-Path $Game '..\Arma 2')).Path
$Cfg  = 'DZE_Server_Config'
$Rpt  = Join-Path $Game "$Cfg\arma2oaserver.RPT"
$FrozenMinutes = 12
$Host.UI.RawUI.WindowTitle = 'DayZ Epoch server watcher (close this window to stop auto-restarts)'

# ---- only one watcher at a time ----
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\DayZEpochWatcher_Chernarus', [ref]$created)
if (-not $created) {
    Write-Host "The server watcher is already running (look for its window on the taskbar)."
    Write-Host "Nothing to do - this window closes in 10 seconds."
    Start-Sleep 10
    exit
}

function Stop-OldServers {
    try {
        Get-CimInstance Win32_Process -Filter "Name='arma2oaserver.exe'" -ErrorAction Stop |
          Where-Object { $_.CommandLine -like '*DZE_Server_Config\server.cfg*' } |
          ForEach-Object {
            Write-Host "$(Get-Date -Format T)  Closing an old server that was still running (PID $($_.ProcessId))"
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
          }
    } catch {}
}

$srvArgs = @('-port=2302',
          "`"-config=$Cfg\server.cfg`"",
          "`"-cfg=$Cfg\basic.cfg`"",
          "`"-profiles=$Cfg`"",
          '-name=server',
          "`"-mod=$A2;EXPANSION;ca;@DayZ_Epoch;@DayZ_Epoch_Server`"",
          '-cpuCount=4', '-exThreads=7', '-maxMem=2047')

while ($true) {
    Stop-OldServers
    Start-Sleep 2

    # make sure the database is up
    Start-Service MariaDB -ErrorAction SilentlyContinue

    # install any updates that were waiting (files named *.pbo.new) - only this server's own files
    @((Join-Path $Game '@DayZ_Epoch_Server\addons\dayz_server.pbo.new'), (Join-Path $Game 'MPMissions\DayZ_Epoch_11.Chernarus.pbo.new')) |
      Where-Object { Test-Path $_ } | Get-Item | ForEach-Object {
        $f = $_.FullName
        $target = $f.Substring(0, $f.Length - 4)
        try {
            Move-Item $f $target -Force -ErrorAction Stop
            Write-Host "$(Get-Date -Format T)  Installed update: $target"
        } catch { Write-Host "$(Get-Date -Format T)  Could not install $f yet (file in use) - will try next restart" }
    }

    $pos      = if (Test-Path $Rpt) { (Get-Item $Rpt).Length } else { 0 }
    $started  = Get-Date
    $lastBeat = $null      # time of the last countdown line seen (null = mission not started yet)
    $carry    = ''
    Write-Host "$(Get-Date -Format T)  Starting DayZ Epoch server... (restarts every 90 minutes once someone joins)"
    $p = Start-Process -FilePath (Join-Path $Game 'arma2oaserver.exe') -ArgumentList $srvArgs `
                       -WorkingDirectory $Game -WindowStyle Minimized -PassThru

    $reason = ''
    while (-not $p.HasExited) {
        Start-Sleep 10
        try {
            if (Test-Path $Rpt) {
                $len = (Get-Item $Rpt).Length
                if ($len -lt $pos) { $pos = 0 }      # log was recreated
                if ($len -gt $pos) {
                    $fs = [System.IO.File]::Open($Rpt, 'Open', 'Read', 'ReadWrite')
                    $null = $fs.Seek($pos, 'Begin')
                    $sr = New-Object System.IO.StreamReader($fs)
                    $new = $carry + $sr.ReadToEnd(); $sr.Close(); $fs.Close()
                    $pos = $len
                    $carry = if ($new.Length -gt 40) { $new.Substring($new.Length - 40) } else { $new }
                    if ($new -match 'DZ RESTART:') {
                        if ($null -eq $lastBeat) { Write-Host "$(Get-Date -Format T)  Mission started - restart countdown is running" }
                        $lastBeat = Get-Date
                        if ($new -match 'DZ RESTART: heartbeat, (\d+) min left') { $host.UI.RawUI.WindowTitle = "DayZ Epoch server watcher - restart in $($Matches[1]) min (close to stop auto-restarts)" }
                    }
                    if ($new -match 'DZ_RESTART_NOW') { $reason = 'Scheduled restart'; break }
                }
            }
        } catch {}
        if (($null -ne $lastBeat) -and (((Get-Date) - $lastBeat).TotalMinutes -gt $FrozenMinutes)) { $reason = 'Server stopped responding (no heartbeat)'; break }
    }

    if ($p.HasExited) {
        Write-Host "$(Get-Date -Format T)  Server stopped on its own (crash or closed). Restarting in 15 seconds..."
    } else {
        Write-Host "$(Get-Date -Format T)  $reason - closing the server..."
        Start-Sleep 5
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        $null = $p.WaitForExit(30000)
    }
    Start-Sleep 15
}

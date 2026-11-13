@echo off
cd /d "%~dp0"
rem Tell Steam this is Arma 2: Operation Arrowhead (same as launching it from Steam) - without this
rem the server can't read Steam IDs and kicks you with "id=ERROR".
set "SteamAppId=33930"
set "SteamGameId=33930"
rem Viv's Epoch by Vivi Snowy - starts the CHERNARUS server (port 2302).
rem It restarts by itself every 90 minutes (counted from when you join) and after crashes.
rem Close the "DayZ Epoch server watcher" window to stop the server for good.
start "DayZ Epoch server watcher" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\server_loop.ps1"

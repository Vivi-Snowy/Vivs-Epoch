@echo off
cd /d "%~dp0"
rem Tell Steam this is Arma 2: Operation Arrowhead (same as launching it from Steam) - without this
rem the server can't read Steam IDs and kicks you with "id=ERROR".
set "SteamAppId=33930"
set "SteamGameId=33930"
if not exist "%~dp0@lingor\addons" goto nomap
if not exist "%~dp0@ibr_plants\addons" goto nomap
if not exist "%~dp0@brg_africa\addons" goto nomap
rem Viv's Epoch by Vivi Snowy - starts the LINGOR server (port 2402).
rem It restarts by itself every 90 minutes (counted from when you join) and after crashes.
rem Close the "DayZ Epoch LINGOR server watcher" window to stop the server for good.
start "DayZ Epoch LINGOR server watcher" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\server_loop_lingor.ps1"
goto :eof
:nomap
echo.
echo   The Lingor map files are not installed yet.
echo   Put lingor-1.5.7z, ibr_plants-1.5.7z and brg_africa-1.23.7z in your Downloads folder,
echo   then run INSTALL.bat again. Download links: README.md on the GitHub page (github.com/Vivi-Snowy).
echo.
pause

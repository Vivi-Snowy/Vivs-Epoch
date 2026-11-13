@echo off
setlocal
cd /d "%~dp0"
rem Tell Steam this is Arma 2: Operation Arrowhead (same as launching it from Steam) - without this
rem the server can't read Steam IDs and kicks you with "id=ERROR".
set "SteamAppId=33930"
set "SteamGameId=33930"
if not exist "%~dp0@lingor\addons" goto nomap
if not exist "%~dp0@ibr_plants\addons" goto nomap
if not exist "%~dp0@brg_africa\addons" goto nomap
rem Viv's Epoch by Vivi Snowy - joins your local LINGOR server.
rem Steam must be running. Start LINGOR_1_START_SERVER.bat first and wait 1-2 minutes.
for %%I in ("%~dp0..\Arma 2") do set "A2=%%~fI"
start "" ArmA2OA.exe -nosplash -skipIntro -world=empty "-mod=%A2%;EXPANSION;ca;@lingor;@ibr_plants;@brg_africa;@DayZ_Epoch" -connect=127.0.0.1 -port=2402
goto :eof
:nomap
echo.
echo   The Lingor map files are not installed yet.
echo   Put lingor-1.5.7z, ibr_plants-1.5.7z and brg_africa-1.23.7z in your Downloads folder,
echo   then run INSTALL.bat again. Download links: README.md on the GitHub page (github.com/Vivi-Snowy).
echo.
pause

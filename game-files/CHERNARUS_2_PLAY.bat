@echo off
setlocal
cd /d "%~dp0"
rem Tell Steam this is Arma 2: Operation Arrowhead (same as launching it from Steam) - without this
rem the server can't read Steam IDs and kicks you with "id=ERROR".
set "SteamAppId=33930"
set "SteamGameId=33930"
rem Viv's Epoch by Vivi Snowy - joins your local CHERNARUS server.
rem Steam must be running. Start CHERNARUS_1_START_SERVER.bat first and wait 1-2 minutes.
for %%I in ("%~dp0..\Arma 2") do set "A2=%%~fI"
start "" ArmA2OA.exe -nosplash -skipIntro -world=empty "-mod=%A2%;EXPANSION;ca;@DayZ_Epoch" -connect=127.0.0.1 -port=2302

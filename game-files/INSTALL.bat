@echo off
title Viv's Epoch by Vivi Snowy - installer
set "PS1=%~dp0setup\install.ps1"
echo.
echo   Viv's Epoch by Vivi Snowy
echo   Starting the installer... click YES when Windows asks for permission.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File \"' + $env:PS1 + '\"')"

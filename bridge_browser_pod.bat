@echo off
set PORT=%1
if "%PORT%"=="" set PORT=8080
powershell -ExecutionPolicy Bypass -File "%~dp0bridge_browser_pod.ps1" %PORT%

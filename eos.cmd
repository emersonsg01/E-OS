@echo off
rem Atalho para o eos.ps1. Funciona mesmo quando o PowerShell bloqueia scripts.
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0eos.ps1" %*
exit /b %ERRORLEVEL%

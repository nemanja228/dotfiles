@echo off
rem Double-clickable wrapper for restore-claude.ps1. See that file for the actual logic.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-claude.ps1"
pause

@echo off
rem Double-clickable wrapper for sync-claude.ps1. See that file for the actual logic.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-claude.ps1"
pause

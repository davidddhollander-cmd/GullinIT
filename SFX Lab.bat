@echo off
rem Opens the SFX Lab (tools/sfx_lab) in your browser: listen to every sound, mark it approved or rejected. Double-click to run; close this window to stop.
rem Keys in the page: Up/Down select, Space play, A approve and next, R reject and next, U reset, N edit note.
cd /d "%~dp0"
title SFX Lab - close this window to stop
set "PY=python"
%PY% --version >nul 2>&1 || set "PY=py -3"
%PY% --version >nul 2>&1 || (
  echo Could not find Python. Install Python 3 and try again.
  pause
  exit /b 1
)
%PY% "%~dp0tools\sfx_lab\sfx_lab.py" --project "%~dp0."
if errorlevel 1 pause

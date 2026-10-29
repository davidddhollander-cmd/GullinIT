@echo off
rem Opens the Art Lab (scenes/art_lab.tscn). Double-click to run. Keys: 1-9/arrows pick, Z zoom, B blind, F filter, I integer scale, P pause, . step, C capture, G new sky, D dusk, Esc quit.
set "GODOT=%~dp0.tools\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=%~dp0..\GullinIt\.tools\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
  echo Could not find Godot_v4.7.2-stable_win64.exe in .tools or ..\GullinIt\.tools
  pause
  exit /b 1
)
start "" "%GODOT%" --path "%~dp0." scenes/art_lab.tscn

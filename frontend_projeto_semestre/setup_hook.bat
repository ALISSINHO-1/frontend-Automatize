@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "BASH_EXE="

where bash >nul 2>nul
if %errorlevel%==0 set "BASH_EXE=bash"

if not defined BASH_EXE if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "BASH_EXE=%LocalAppData%\Programs\Git\bin\bash.exe"

if not defined BASH_EXE (
  echo [setup] ERROR: Git Bash was not found.
  echo [setup] Install Git for Windows and run this file again.
  pause
  exit /b 1
)

"%BASH_EXE%" "%SCRIPT_DIR%setup_hooks.sh"
if errorlevel 1 (
  echo.
  echo [setup] Hook installation failed.
  pause
  exit /b 1
)

echo.
echo [setup] Version hook installed successfully.
pause

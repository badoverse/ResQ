@echo off
rem Portable Ollama + offline library for Windows, run from this USB stick.
rem Usage:
rem   start-ai.bat              open the chat + library in the browser
rem   start-ai.bat terminal     chat in this window instead
rem   start-ai.bat run MODEL    chat with MODEL in this window
rem   start-ai.bat pull MODEL   download MODEL onto the stick (needs internet)
rem AI server: 127.0.0.1:11435 (never clashes with an installed Ollama on 11434).
rem Chat page + library: http://127.0.0.1:8090/
setlocal EnableDelayedExpansion

set "DIR=%~dp0"
set "BIN=%DIR%ollama\windows\ollama.exe"
set "KIWIX=%DIR%kiwix\windows\kiwix-serve.exe"
set "WEB_PORT=8090"
set "OLLAMA_MODELS=%DIR%models"
if not defined OLLAMA_HOST set "OLLAMA_HOST=127.0.0.1:11435"
if not defined OLLAMA_CONTEXT_LENGTH set "OLLAMA_CONTEXT_LENGTH=8192"
if not defined OLLAMA_KEEP_ALIVE set "OLLAMA_KEEP_ALIVE=5m"
rem Fully local: no Ollama cloud models or cloud features.
set "OLLAMA_NO_CLOUD=1"

if not exist "%BIN%" (
  echo Ollama for Windows not found at %BIN%
  pause & exit /b 1
)

"%BIN%" list >nul 2>&1
if errorlevel 1 (
  echo Starting portable Ollama on %OLLAMA_HOST% ...
  start "Portable Ollama server" /min "%BIN%" serve
  for /l %%i in (1,1,30) do (
    timeout /t 1 /nobreak >nul
    "%BIN%" list >nul 2>&1 && goto :ready
  )
  echo Server failed to start.
  pause & exit /b 1
)
:ready

if "%~1"=="terminal" goto :terminal
if not "%~1"=="" (
  "%BIN%" %*
  goto :end
)

rem Browser mode: chat page + offline library served by kiwix-serve.
set "ZIMS="
for %%z in ("%DIR%library\*.zim") do set ZIMS=!ZIMS! "%%~fz"
echo Starting chat page and library on http://127.0.0.1:%WEB_PORT%/ ...
start "Portable library server" /min "%KIWIX%" --address=127.0.0.1 --port=%WEB_PORT% "--customIndex=%DIR%chat.html" !ZIMS!
timeout /t 3 /nobreak >nul
start "" "http://127.0.0.1:%WEB_PORT%/"
echo.
echo Chat is open in your browser: http://127.0.0.1:%WEB_PORT%/
echo.
pause
echo Stopping the AI and the library...
rem Stop only the windows this script started (never an Ollama installed on the computer).
taskkill /fi "WINDOWTITLE eq Portable library server*" /t /f >nul 2>&1
taskkill /fi "WINDOWTITLE eq Portable Ollama server*" /t /f >nul 2>&1
exit /b 0

:terminal
echo Models on this stick:
set N=0
for /f "skip=1 tokens=1" %%m in ('"%BIN%" list') do (
  set /a N+=1
  set "M!N!=%%m"
  echo   !N!^) %%m
)
if %N%==0 (
  echo No models on the stick. Add one: start-ai.bat pull qwen2.5:3b
  pause & exit /b 1
)
set /p PICK=Pick a number:
set "MODEL=!M%PICK%!"
if "%MODEL%"=="" ( echo Invalid choice. & pause & exit /b 1 )
"%BIN%" run %MODEL%

:end
echo.
echo The server keeps running in the minimized "Portable Ollama server" window. Close it to stop.
pause

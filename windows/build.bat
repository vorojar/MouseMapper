@echo off
setlocal

echo ========================================
echo   MouseMapper Windows - Build
echo ========================================
echo.

:: Try gcc in PATH first
where gcc >nul 2>&1
if %errorlevel%==0 goto :found_gcc

:: Search WinGet MinGW installation
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\*MinGW*") do (
    if exist "%%D\*\bin\gcc.exe" (
        for /d %%B in ("%%D\*") do (
            if exist "%%B\bin\gcc.exe" (
                set "PATH=%%B\bin;%PATH%"
                goto :found_gcc
            )
        )
    )
)

echo [FAIL] gcc not found.
echo Please install MinGW-w64 or run from Git Bash.
echo.
pause
exit /b 1

:found_gcc
echo [OK] Found gcc
windres app.rc -o app.res
if %errorlevel% neq 0 (
    echo [FAIL] windres failed
    pause
    exit /b 1
)

gcc -O2 -Wall -mwindows -o MouseMapper.exe main.c config.c hook.c app.res -lshell32 -lole32 -ladvapi32
if %errorlevel% neq 0 (
    echo [FAIL] gcc failed
    pause
    exit /b 1
)

del /q app.res 2>nul
echo.
echo [OK] Build success: MouseMapper.exe
echo.
pause

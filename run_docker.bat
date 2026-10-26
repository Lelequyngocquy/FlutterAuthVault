@echo off
rem Launcher for AuthVault Docker on Windows
setlocal
set "SCRIPT_DIR=%~dp0"
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%SCRIPT_DIR%scripts\docker_run.sh" %*
    goto :end
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%SCRIPT_DIR%scripts\docker_run.sh" %*
    goto :end
)
where git >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%I in ('where git') do (
        if exist "%%~dpI..\bin\bash.exe" (
            "%%~dpI..\bin\bash.exe" "%SCRIPT_DIR%scripts\docker_run.sh" %*
            goto :end
        )
    )
)
echo [WARN] Git Bash not detected. Invoking docker compose directly...
docker compose -f "%SCRIPT_DIR%docker-compose.yml" up -d
:end
exit /b %ERRORLEVEL%

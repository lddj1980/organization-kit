@echo off
setlocal

echo ==========================================
echo Organization Kit Installer
echo ==========================================
echo.

set "SCRIPT_DIR=%~dp0"

REM Check if PowerShell is available
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available on this system.
    echo Please install PowerShell to continue.
    exit /b 1
)

if "%~1"=="" (
    set /p TARGET_PATH=Informe o diretorio alvo: 
) else (
    set "TARGET_PATH=%~1"
)

if "%~2"=="" (
    set "ADAPTER=claude"
) else (
    set "ADAPTER=%~2"
)

if /I "%~3"=="-Force" (
    set "FORCE_ARG=-Force"
) else if /I "%~3"=="force" (
    set "FORCE_ARG=-Force"
) else (
    set "FORCE_ARG="
)

echo Target path: %TARGET_PATH%
echo Adapter: %ADAPTER%
if defined FORCE_ARG echo Force overwrite: yes
echo.

if not exist "%TARGET_PATH%" (
    mkdir "%TARGET_PATH%"
)

if /I "%ADAPTER%"=="claude" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\install.ps1" -TargetPath "%TARGET_PATH%" -Adapter "%ADAPTER%" %FORCE_ARG%
) else (
    REM Create base project structure without agent-specific commands
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\install.ps1" -TargetPath "%TARGET_PATH%" -SkipCommands %FORCE_ARG%
    if errorlevel 1 (
        echo.
        echo Erro durante a preparacao do diretorio.
        exit /b 1
    )
    REM Install the requested adapter into the target directory
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Set-Location '%TARGET_PATH%'; & '%SCRIPT_DIR%setup.ps1' -Integration '%ADAPTER%' %FORCE_ARG% }"
)

if errorlevel 1 (
    echo.
    echo Erro durante a instalacao.
    exit /b 1
)

echo.
echo ==========================================
echo Instalacao concluida com sucesso!
echo ==========================================
echo.
echo Proximos passos:
echo   1. Abra o projeto no seu agente/IDE (%ADAPTER%)
echo   2. Execute /org.init [nome-da-organizacao]
echo   3. Siga o dialogo de descoberta
echo.
endlocal

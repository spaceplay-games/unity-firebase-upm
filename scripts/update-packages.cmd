@echo off
setlocal enabledelayedexpansion

:: Firebase UPM Package Updater (Windows CMD version)
:: Usage: update-packages.cmd [version]

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "TEMP_DIR=%ROOT_DIR%\temp"
set "PACKAGES_DIR=%ROOT_DIR%\packages"

:: Firebase packages to download
set PACKAGES=com.google.firebase.app com.google.firebase.analytics com.google.firebase.crashlytics com.google.firebase.app-check com.google.firebase.auth com.google.firebase.firestore com.google.firebase.functions com.google.firebase.storage com.google.firebase.database com.google.firebase.remote-config com.google.firebase.messaging com.google.firebase.installations

echo.
echo ========================================
echo   Firebase UPM Package Updater
echo ========================================
echo.

:: Get version from argument or fetch latest
if "%~1"=="" (
    echo [INFO] Fetching latest Firebase version...
    for /f "tokens=*" %%i in ('powershell -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/firebase/firebase-unity-sdk/releases/latest').tag_name -replace '^v',''"') do set "VERSION=%%i"
) else (
    set "VERSION=%~1"
)

echo   Version: %VERSION%
echo.

:: Create directories
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if not exist "%PACKAGES_DIR%" mkdir "%PACKAGES_DIR%"

:: Download packages
echo [INFO] Downloading Firebase packages from Google Registry...
set DOWNLOAD_COUNT=0

for %%p in (%PACKAGES%) do (
    echo   Downloading %%p...
    powershell -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://dl.google.com/games/registry/unity/%%p/%%p-%VERSION%.tgz' -OutFile '%TEMP_DIR%\%%p.tgz' -ErrorAction Stop; Write-Host '    OK' -ForegroundColor Green } catch { Write-Host '    FAILED' -ForegroundColor Yellow }"
)

:: Download EDM4U
echo.
echo [INFO] Downloading External Dependency Manager...
powershell -Command "$ProgressPreference='SilentlyContinue'; $r = Invoke-RestMethod -Uri 'https://api.github.com/repos/googlesamples/unity-jar-resolver/releases/latest'; $asset = $r.assets | Where-Object { $_.name -match 'external-dependency-manager.*\.tgz$' } | Select-Object -First 1; if ($asset) { Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%TEMP_DIR%\edm4u.tgz'; Write-Host '    OK' -ForegroundColor Green } else { Write-Host '    FAILED' -ForegroundColor Yellow }"

:: Extract packages
echo.
echo [INFO] Extracting packages...

for %%p in (%PACKAGES%) do (
    if exist "%TEMP_DIR%\%%p.tgz" (
        echo   Extracting %%p...
        if exist "%PACKAGES_DIR%\%%p" rmdir /s /q "%PACKAGES_DIR%\%%p"
        mkdir "%PACKAGES_DIR%\%%p"
        tar -xzf "%TEMP_DIR%\%%p.tgz" -C "%PACKAGES_DIR%\%%p" --strip-components=1
        if !errorlevel! equ 0 (
            echo     OK
        ) else (
            echo     FAILED
        )
    )
)

:: Extract EDM4U
if exist "%TEMP_DIR%\edm4u.tgz" (
    echo   Extracting com.google.external-dependency-manager...
    if exist "%PACKAGES_DIR%\com.google.external-dependency-manager" rmdir /s /q "%PACKAGES_DIR%\com.google.external-dependency-manager"
    mkdir "%PACKAGES_DIR%\com.google.external-dependency-manager"
    tar -xzf "%TEMP_DIR%\edm4u.tgz" -C "%PACKAGES_DIR%\com.google.external-dependency-manager" --strip-components=1
    if !errorlevel! equ 0 (
        echo     OK
    ) else (
        echo     FAILED
    )
)

:: Update VERSION file
echo %VERSION%> "%ROOT_DIR%\VERSION"

:: Cleanup
echo.
echo [INFO] Cleaning up temporary files...
rmdir /s /q "%TEMP_DIR%" 2>nul

:: Summary
echo.
echo ========================================
echo   Update Complete!
echo ========================================
echo.
echo   Updated to Firebase SDK v%VERSION%
echo.

:: List extracted packages
echo   Packages:
for %%p in (%PACKAGES%) do (
    if exist "%PACKAGES_DIR%\%%p\package.json" (
        echo     - %%p
    )
)
if exist "%PACKAGES_DIR%\com.google.external-dependency-manager\package.json" (
    echo     - com.google.external-dependency-manager
)

echo.
endlocal

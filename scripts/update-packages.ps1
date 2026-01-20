# Firebase UPM Package Updater (PowerShell version for Windows)
# Downloads packages directly from Google's registry
# Usage: .\update-packages.ps1 [-Version "13.6.0"] [-Force]

param(
    [string]$Version,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$TempDir = Join-Path $RootDir "temp"
$PackagesDir = Join-Path $RootDir "packages"

# Firebase packages to download from Google's registry
$FirebasePackages = @(
    "com.google.firebase.app"
    "com.google.firebase.analytics"
    "com.google.firebase.crashlytics"
    "com.google.firebase.app-check"
    "com.google.firebase.auth"
    "com.google.firebase.firestore"
    "com.google.firebase.functions"
    "com.google.firebase.storage"
    "com.google.firebase.database"
    "com.google.firebase.remote-config"
    "com.google.firebase.messaging"
    "com.google.firebase.installations"
)

function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Green
}

function Write-Warn($message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
}

function Write-Err($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

function Write-Success($message) {
    Write-Host "[OK] $message" -ForegroundColor Cyan
}

function Get-LatestVersion {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/firebase/firebase-unity-sdk/releases/latest"
    return $response.tag_name -replace '^v', ''
}

function Get-CurrentVersion {
    $versionFile = Join-Path $RootDir "VERSION"
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }
    return "0.0.0"
}

function Expand-TarGz {
    param(
        [string]$TgzPath,
        [string]$DestinationPath
    )

    # Use Windows tar.exe directly (available in Windows 10 1803+)
    $tarExe = "$env:SystemRoot\System32\tar.exe"

    if (Test-Path $tarExe) {
        # Use native Windows tar
        & $tarExe -xzf $TgzPath -C $DestinationPath --strip-components=1 2>$null
        return $LASTEXITCODE -eq 0
    }

    # Fallback: Use .NET to decompress gzip, then tar
    try {
        Add-Type -AssemblyName System.IO.Compression

        # Decompress .tgz to .tar
        $tarPath = $TgzPath -replace '\.tgz$', '.tar'

        $gzipStream = [System.IO.File]::OpenRead($TgzPath)
        $decompressedStream = New-Object System.IO.Compression.GZipStream($gzipStream, [System.IO.Compression.CompressionMode]::Decompress)
        $tarOutputStream = [System.IO.File]::Create($tarPath)
        $decompressedStream.CopyTo($tarOutputStream)
        $tarOutputStream.Close()
        $decompressedStream.Close()
        $gzipStream.Close()

        # Extract tar using Windows tar
        & $tarExe -xf $tarPath -C $DestinationPath --strip-components=1 2>$null
        $result = $LASTEXITCODE -eq 0

        # Cleanup tar file
        Remove-Item $tarPath -Force -ErrorAction SilentlyContinue

        return $result
    }
    catch {
        return $false
    }
}

function Invoke-FirebasePackageDownload($pkgName, $version) {
    $url = "https://dl.google.com/games/registry/unity/${pkgName}/${pkgName}-${version}.tgz"
    $tgzPath = Join-Path $TempDir "${pkgName}.tgz"

    try {
        Write-Host "  Downloading $pkgName..." -NoNewline
        Invoke-WebRequest -Uri $url -OutFile $tgzPath -ErrorAction Stop
        Write-Host " OK" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Yellow
        return $false
    }
}

function Expand-Package($pkgName) {
    $tgzFile = Join-Path $TempDir "${pkgName}.tgz"

    if (-not (Test-Path $tgzFile)) {
        return $false
    }

    Write-Host "  Extracting $pkgName..." -NoNewline

    $pkgDir = Join-Path $PackagesDir $pkgName

    # Clean and recreate package directory
    if (Test-Path $pkgDir) {
        Remove-Item -Path $pkgDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

    if (Expand-TarGz -TgzPath $tgzFile -DestinationPath $pkgDir) {
        Write-Host " OK" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        return $false
    }
}

function Get-EDM4U {
    Write-Info "Downloading External Dependency Manager..."

    try {
        # Get latest EDM4U version from GitHub releases
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/googlesamples/unity-jar-resolver/releases/latest"
        $edmVersion = $response.tag_name -replace '^v', ''

        # Download from Google's registry (same pattern as Firebase packages)
        $url = "https://dl.google.com/games/registry/unity/com.google.external-dependency-manager/com.google.external-dependency-manager-${edmVersion}.tgz"
        $edmPath = Join-Path $TempDir "edm4u.tgz"

        Write-Host "  Downloading com.google.external-dependency-manager v${edmVersion}..." -NoNewline
        Invoke-WebRequest -Uri $url -OutFile $edmPath -ErrorAction Stop
        Write-Host " OK" -ForegroundColor Green

        $pkgDir = Join-Path $PackagesDir "com.google.external-dependency-manager"

        if (Test-Path $pkgDir) {
            Remove-Item -Path $pkgDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

        Write-Host "  Extracting com.google.external-dependency-manager..." -NoNewline

        if (Expand-TarGz -TgzPath $edmPath -DestinationPath $pkgDir) {
            Write-Host " OK" -ForegroundColor Green
            return $true
        }

        Write-Host " FAILED" -ForegroundColor Yellow
        return $false
    }
    catch {
        Write-Warn "Could not download EDM4U: $_"
        return $false
    }
}

function Remove-TempFiles {
    Write-Info "Cleaning up temporary files..."
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Main script
try {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Firebase UPM Package Updater" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Check for Windows tar
    $tarExe = "$env:SystemRoot\System32\tar.exe"
    if (-not (Test-Path $tarExe)) {
        Write-Err "Windows tar.exe not found. Please ensure you're running Windows 10 1803 or later."
        exit 1
    }

    if (-not $Version) {
        Write-Info "Fetching latest Firebase version..."
        $Version = Get-LatestVersion
    }

    $currentVersion = Get-CurrentVersion

    Write-Host ""
    Write-Host "  Latest version:  " -NoNewline
    Write-Host $Version -ForegroundColor Yellow
    Write-Host "  Current version: " -NoNewline
    Write-Host $currentVersion -ForegroundColor Yellow
    Write-Host ""

    if ($Version -eq $currentVersion -and -not $Force) {
        Write-Success "Already up to date!"
        exit 0
    }

    # Create directories
    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }
    if (-not (Test-Path $PackagesDir)) {
        New-Item -ItemType Directory -Path $PackagesDir -Force | Out-Null
    }

    # Download Firebase packages
    Write-Info "Downloading Firebase packages from Google Registry..."
    $downloadedCount = 0
    foreach ($pkg in $FirebasePackages) {
        if (Invoke-FirebasePackageDownload $pkg $Version) {
            $downloadedCount++
        }
    }

    # Download EDM4U
    Get-EDM4U | Out-Null

    # Extract packages
    Write-Host ""
    Write-Info "Extracting packages..."
    $extractedCount = 0
    foreach ($pkg in $FirebasePackages) {
        if (Expand-Package $pkg) {
            $extractedCount++
        }
    }

    # Update VERSION file
    [System.IO.File]::WriteAllText((Join-Path $RootDir "VERSION"), $Version)

    # Cleanup
    Remove-TempFiles

    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Update Complete!" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Success "Updated to Firebase SDK v$Version"
    Write-Host ""
    Write-Host "  Packages extracted: $extractedCount / $($FirebasePackages.Count)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Packages:" -ForegroundColor White

    foreach ($pkg in $FirebasePackages) {
        $pkgDir = Join-Path $PackagesDir $pkg
        if (Test-Path $pkgDir) {
            $pkgJson = Join-Path $pkgDir "package.json"
            if (Test-Path $pkgJson) {
                $pkgData = Get-Content $pkgJson -Raw | ConvertFrom-Json
                Write-Host "    - $pkg @ $($pkgData.version)" -ForegroundColor Gray
            }
        }
    }

    $edmDir = Join-Path $PackagesDir "com.google.external-dependency-manager"
    if (Test-Path $edmDir) {
        $edmJson = Join-Path $edmDir "package.json"
        if (Test-Path $edmJson) {
            $edmData = Get-Content $edmJson -Raw | ConvertFrom-Json
            Write-Host "    - com.google.external-dependency-manager @ $($edmData.version)" -ForegroundColor Gray
        }
    }

    Write-Host ""
}
catch {
    Write-Err $_.Exception.Message
    Remove-TempFiles
    exit 1
}

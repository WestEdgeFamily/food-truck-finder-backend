# Food Truck App Build Fix Script
# This script handles cross-drive issues and Kotlin build problems

Write-Host "Food Truck App Build Fix Script v2.2.1" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator (recommended for symlink operations)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "WARNING: Not running as administrator. Some operations may fail." -ForegroundColor Yellow
    Write-Host "Consider running PowerShell as Administrator for best results." -ForegroundColor Yellow
    Write-Host ""
}

# Check JAVA_HOME
if (-not $env:JAVA_HOME) {
    Write-Host "ERROR: JAVA_HOME is not set!" -ForegroundColor Red
    Write-Host "Please set JAVA_HOME to your Java installation directory" -ForegroundColor Red
    Write-Host "Example: `$env:JAVA_HOME = 'C:\Program Files\Java\jdk-17'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can download Java from: https://adoptium.net/" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ JAVA_HOME is set to: $env:JAVA_HOME" -ForegroundColor Green
Write-Host ""

# Navigate to project directory
Set-Location -Path $PSScriptRoot

Write-Host "Step 1: Deep cleaning all build artifacts..." -ForegroundColor Yellow

# Clean Flutter
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter clean failed, but continuing..." -ForegroundColor Yellow
}

# Remove build directories with force
$dirsToRemove = @(
    "build",
    ".dart_tool",
    ".gradle",
    "android\.gradle",
    "android\app\build",
    "android\app\.cxx",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".packages"
)

foreach ($dir in $dirsToRemove) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Removed: $dir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Step 2: Clearing global Gradle and Kotlin caches..." -ForegroundColor Yellow

# Clear Gradle cache
$gradleCache = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCache) {
    Get-ChildItem -Path $gradleCache -Directory | Where-Object { $_.Name -like "*kotlin*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Cleared Kotlin caches from Gradle" -ForegroundColor Gray
}

# Clear Kotlin daemon logs
$kotlinDaemon = "$env:USERPROFILE\.kotlin\daemon"
if (Test-Path $kotlinDaemon) {
    Remove-Item -Path $kotlinDaemon -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Cleared Kotlin daemon directory" -ForegroundColor Gray
}

# Clear temp files
$tempDirs = @(
    "$env:TEMP",
    "$env:TMP"
)

foreach ($tempDir in $tempDirs) {
    if (Test-Path $tempDir) {
        Get-ChildItem -Path $tempDir -Filter "*kotlin*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path $tempDir -Filter "*.lock" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  Cleared temporary files" -ForegroundColor Gray

Write-Host ""
Write-Host "Step 3: Running Android Gradle clean..." -ForegroundColor Yellow

Push-Location android
if (Test-Path "gradlew.bat") {
    & .\gradlew.bat clean --no-daemon
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Gradle clean failed, but continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Host "  gradlew.bat not found, skipping..." -ForegroundColor Yellow
}
Pop-Location

Write-Host ""
Write-Host "Step 4: Getting fresh dependencies..." -ForegroundColor Yellow

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: flutter pub get failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 5: Checking Flutter doctor..." -ForegroundColor Yellow

flutter doctor -v | Select-String -Pattern "(Flutter|Android|Java)" | ForEach-Object { Write-Host $_ -ForegroundColor Gray }

Write-Host ""
Write-Host "Step 6: Building AAB bundle..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Gray

# Set environment variables for build
$env:FLUTTER_BUILD_MODE = "release"

# Build with additional flags to help with cross-drive issues
flutter build appbundle `
    --release `
    --no-tree-shake-icons `
    --dart-define=API_URL=https://food-truck-finder-api.onrender.com/api `
    --dart-define=ENABLE_PUSH=true `
    --dart-define=ENABLE_SOCIAL_LOGIN=true `
    --dart-define=ENABLE_ANALYTICS=true `
    --verbose

$buildSuccess = $LASTEXITCODE -eq 0

Write-Host ""
Write-Host "Step 7: Checking build result..." -ForegroundColor Yellow

$aabPath = "build\app\outputs\bundle\release\app-release.aab"
if ($buildSuccess -and (Test-Path $aabPath)) {
    $outputPath = "..\food-truck-v2.2.1-build86-FINAL.aab"
    Copy-Item -Path $aabPath -Destination $outputPath -Force
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "AAB saved as: food-truck-v2.2.1-build86-FINAL.aab" -ForegroundColor Green
    Write-Host "File size: $((Get-Item $outputPath).Length / 1MB) MB" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "BUILD FAILED!" -ForegroundColor Red
    Write-Host "" -ForegroundColor Red
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Close all IDEs and file explorers" -ForegroundColor Yellow
    Write-Host "2. Run this script as Administrator" -ForegroundColor Yellow
    Write-Host "3. If cross-drive issues persist:" -ForegroundColor Yellow
    Write-Host "   - Move project to C: drive (same as Flutter SDK)" -ForegroundColor Yellow
    Write-Host "   - OR install Flutter on D: drive" -ForegroundColor Yellow
    Write-Host "4. Check 'flutter doctor -v' output above" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"
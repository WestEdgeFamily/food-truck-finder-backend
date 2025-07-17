# Food Truck Finder - Production AAB Builder
# PowerShell Version

# Requires running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Food Truck Finder - Production AAB Builder" -ForegroundColor Cyan
Write-Host "Version: 2.0.0" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Function to check command success
function Check-LastCommand {
    param($ErrorMessage)
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: $ErrorMessage" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

try {
    # Step 1: Clean
    Write-Host "[1/8] Cleaning previous builds..." -ForegroundColor Green
    flutter clean
    Check-LastCommand "Flutter clean failed"

    # Step 2: Get dependencies
    Write-Host ""
    Write-Host "[2/8] Getting Flutter dependencies..." -ForegroundColor Green
    flutter pub get
    Check-LastCommand "Flutter pub get failed"

    # Step 3: Run build runner (optional)
    Write-Host ""
    Write-Host "[3/8] Running code generation..." -ForegroundColor Green
    flutter pub run build_runner build --delete-conflicting-outputs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Build runner failed, continuing anyway..." -ForegroundColor Yellow
    }

    # Step 4: Verify API endpoint
    Write-Host ""
    Write-Host "[4/8] Verifying API endpoint..." -ForegroundColor Green
    Write-Host "Current API: https://food-truck-finder-api.onrender.com/api" -ForegroundColor Cyan
    
    # Test API connection
    try {
        $response = Invoke-WebRequest -Uri "https://food-truck-finder-api.onrender.com/api/health" -UseBasicParsing -TimeoutSec 10
        Write-Host "✓ API is reachable" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Warning: Could not reach API (build will continue)" -ForegroundColor Yellow
    }

    # Step 5: Check key.properties
    Write-Host ""
    Write-Host "[5/8] Checking key.properties..." -ForegroundColor Green
    $keyPropertiesPath = "android\key.properties"
    if (-not (Test-Path $keyPropertiesPath)) {
        Write-Host "ERROR: $keyPropertiesPath not found!" -ForegroundColor Red
        Write-Host "Please create key.properties with your keystore information." -ForegroundColor Yellow
        Write-Host "Example content:" -ForegroundColor Yellow
        Write-Host "  storePassword=your_store_password" -ForegroundColor Gray
        Write-Host "  keyPassword=your_key_password" -ForegroundColor Gray
        Write-Host "  keyAlias=upload" -ForegroundColor Gray
        Write-Host "  storeFile=../upload-keystore.jks" -ForegroundColor Gray
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "✓ key.properties found" -ForegroundColor Green

    # Step 6: Check keystore
    Write-Host ""
    Write-Host "[6/8] Checking keystore..." -ForegroundColor Green
    $keystorePath = "android\upload-keystore.jks"
    if (-not (Test-Path $keystorePath)) {
        Write-Host "ERROR: $keystorePath not found!" -ForegroundColor Red
        Write-Host "Please ensure your keystore file is in the android directory." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "✓ Keystore found" -ForegroundColor Green

    # Step 7: Build AAB
    Write-Host ""
    Write-Host "[7/8] Building Release AAB..." -ForegroundColor Green
    Write-Host "This may take 5-10 minutes..." -ForegroundColor Yellow
    
    $startTime = Get-Date
    flutter build appbundle --release
    Check-LastCommand "Flutter build failed"
    
    $endTime = Get-Date
    $buildTime = $endTime - $startTime
    
    # Step 8: Verify output
    Write-Host ""
    Write-Host "[8/8] Verifying build output..." -ForegroundColor Green
    $aabPath = "build\app\outputs\bundle\release\app-release.aab"
    
    if (Test-Path $aabPath) {
        $aabInfo = Get-Item $aabPath
        $aabSizeMB = [math]::Round($aabInfo.Length / 1MB, 2)
        
        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Green
        Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
        Write-Host "=============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "PRODUCTION AAB DETAILS:" -ForegroundColor Cyan
        Write-Host "Location: $aabPath" -ForegroundColor White
        Write-Host "Size: $aabSizeMB MB" -ForegroundColor White
        Write-Host "Version: 2.0.0 (Build 79)" -ForegroundColor White
        Write-Host "Build Time: $($buildTime.Minutes) minutes $($buildTime.Seconds) seconds" -ForegroundColor White
        Write-Host ""
        Write-Host "NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "1. Upload AAB to Google Play Console" -ForegroundColor White
        Write-Host "2. Fill in release notes" -ForegroundColor White
        Write-Host "3. Submit for review" -ForegroundColor White
        Write-Host ""
        Write-Host "RELEASE NOTES SUGGESTION:" -ForegroundColor Cyan
        Write-Host "• Enhanced security with password encryption" -ForegroundColor White
        Write-Host "• Improved performance with pagination" -ForegroundColor White
        Write-Host "• Added offline support" -ForegroundColor White
        Write-Host "• Better error handling and retry mechanisms" -ForegroundColor White
        Write-Host "• UI/UX improvements with loading states" -ForegroundColor White
        Write-Host "• Fixed menu display issues" -ForegroundColor White
        Write-Host "• Added photo upload functionality" -ForegroundColor White
        Write-Host ""
        
        # Offer to open output folder
        $openFolder = Read-Host "Open output folder? (Y/N)"
        if ($openFolder -eq 'Y' -or $openFolder -eq 'y') {
            explorer.exe "build\app\outputs\bundle\release"
        }
    } else {
        Write-Host "ERROR: AAB file not found at expected location!" -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host "BUILD FAILED!" -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Read-Host "Press Enter to exit" 
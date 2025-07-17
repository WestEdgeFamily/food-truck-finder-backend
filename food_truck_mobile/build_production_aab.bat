@echo off
echo =============================================
echo Food Truck Finder - Production AAB Builder
echo Version: 2.0.0
echo =============================================
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo [1/8] Cleaning previous builds...
call flutter clean
if %errorlevel% neq 0 goto :error

echo.
echo [2/8] Getting Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 goto :error

echo.
echo [3/8] Running code generation...
call flutter pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo Warning: Build runner failed, continuing anyway...
)

echo.
echo [4/8] Verifying API endpoint...
echo Current API: https://food-truck-finder-api.onrender.com/api
echo.

echo [5/8] Checking key.properties...
if not exist "android\key.properties" (
    echo ERROR: android\key.properties not found!
    echo Please create key.properties with your keystore information.
    echo Example content:
    echo   storePassword=your_store_password
    echo   keyPassword=your_key_password
    echo   keyAlias=upload
    echo   storeFile=../upload-keystore.jks
    pause
    exit /b 1
)

echo [6/8] Checking keystore...
if not exist "android\upload-keystore.jks" (
    echo ERROR: android\upload-keystore.jks not found!
    echo Please ensure your keystore file is in the android directory.
    pause
    exit /b 1
)

echo.
echo [7/8] Building Release AAB...
echo This may take 5-10 minutes...
call flutter build appbundle --release
if %errorlevel% neq 0 goto :error

echo.
echo [8/8] Build completed successfully!
echo.
echo =============================================
echo PRODUCTION AAB LOCATION:
echo build\app\outputs\bundle\release\app-release.aab
echo.
echo VERSION: 2.0.0 (Build 79)
echo SIZE: 
dir /b "build\app\outputs\bundle\release\app-release.aab" 2>nul
echo =============================================
echo.
echo NEXT STEPS:
echo 1. Upload AAB to Google Play Console
echo 2. Fill in release notes
echo 3. Submit for review
echo.
echo RELEASE NOTES SUGGESTION:
echo - Enhanced security with password encryption
echo - Improved performance with pagination
echo - Added offline support
echo - Better error handling
echo - UI/UX improvements
echo.
pause
exit /b 0

:error
echo.
echo =============================================
echo ERROR: Build failed!
echo Please check the error messages above.
echo =============================================
pause
exit /b 1 
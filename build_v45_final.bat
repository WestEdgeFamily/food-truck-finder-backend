@echo off
echo ======================================
echo   Building Food Truck App v1.45.0
echo   CALL BUTTON FIX AND IMPROVEMENTS
echo ======================================
echo.

echo Setting up build environment...
set "PROJECT_DIR=%~dp0food_truck_mobile"
set "OUTPUT_DIR=%~dp0"

echo Changing to project directory: %PROJECT_DIR%
cd /d "%PROJECT_DIR%"

echo.
echo [1/6] Cleaning previous build...
flutter clean

echo.
echo [2/6] Getting dependencies...
flutter pub get

echo.
echo [3/6] Running code generation...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo.
echo [4/6] Building Android App Bundle for Play Store...
flutter build appbundle --release --build-name=1.45.0 --build-number=45

echo.
echo [5/6] Building APK for testing...
flutter build apk --release --build-name=1.45.0 --build-number=45

echo.
echo [6/6] Copying files to output directory...
if exist "build\app\outputs\bundle\release\app-release.aab" (
    copy "build\app\outputs\bundle\release\app-release.aab" "%OUTPUT_DIR%food-truck-CALL-FIX-v1.45.0.aab"
    echo ✅ AAB copied to: food-truck-CALL-FIX-v1.45.0.aab
) else (
    echo ❌ AAB file not found!
)

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "%OUTPUT_DIR%food-truck-CALL-FIX-v1.45.0.apk"
    echo ✅ APK copied to: food-truck-CALL-FIX-v1.45.0.apk
) else (
    echo ❌ APK file not found!
)

echo.
echo ======================================
echo   BUILD COMPLETE - VERSION 1.45.0
echo ======================================
echo.
echo PLAY STORE DEPLOYMENT:
echo AAB File: food-truck-CALL-FIX-v1.45.0.aab
echo.
echo TESTING:
echo APK File: food-truck-CALL-FIX-v1.45.0.apk
echo.
echo ======================================
echo   FIXES IN VERSION 1.45.0
echo ======================================
echo.
echo ✅ FIXED: Call button functionality
echo ✅ FIXED: Phone number formatting for tel: URLs
echo ✅ IMPROVED: Error handling for phone calls
echo ✅ ADDED: User feedback for failed phone calls
echo ✅ ENHANCED: Phone number cleaning (removes formatting)
echo ✅ MAINTAINED: Email button functionality
echo.
echo VERSION: 1.45.0+45
echo.
echo Ready to upload to Google Play Console!
echo.
pause 
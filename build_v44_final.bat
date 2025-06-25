@echo off
echo ======================================
echo   Building Food Truck App v1.44.0
echo   LATEST FEATURES AND IMPROVEMENTS
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
flutter build appbundle --release --build-name=1.44.0 --build-number=44

echo.
echo [5/6] Building APK for testing...
flutter build apk --release --build-name=1.44.0 --build-number=44

echo.
echo [6/6] Copying files to output directory...
if exist "build\app\outputs\bundle\release\app-release.aab" (
    copy "build\app\outputs\bundle\release\app-release.aab" "%OUTPUT_DIR%food-truck-v1.44.0.aab"
    echo ✅ AAB copied to: food-truck-v1.44.0.aab
) else (
    echo ❌ AAB file not found!
)

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "%OUTPUT_DIR%food-truck-v1.44.0.apk"
    echo ✅ APK copied to: food-truck-v1.44.0.apk
) else (
    echo ❌ APK file not found!
)

echo.
echo ======================================
echo   BUILD COMPLETE - VERSION 1.44.0
echo ======================================
echo.
echo PLAY STORE DEPLOYMENT:
echo AAB File: food-truck-v1.44.0.aab
echo.
echo TESTING:
echo APK File: food-truck-v1.44.0.apk
echo.
echo ======================================
echo   FEATURES IN VERSION 1.44.0
echo ======================================
echo.
echo ✅ Enhanced food truck discovery
echo ✅ Improved location tracking
echo ✅ Updated UI components
echo ✅ Performance optimizations
echo ✅ Bug fixes and stability improvements
echo ✅ Cloud backend integration
echo.
echo VERSION: 1.44.0+44
echo.
echo Ready to upload to Google Play Console!
echo.
pause 
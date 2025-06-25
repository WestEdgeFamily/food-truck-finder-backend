@echo off
echo Building Food Truck App AAB Bundle for Cloud Backend (v1.42.0) - Alternative Method...
echo.

REM Set the project directory without spaces in the path
set "PROJECT_DIR=C:\Users\Cody Vincent\Desktop\Food Truck App\food_truck_mobile"

REM Change to project directory
cd /d "%PROJECT_DIR%"

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building AAB bundle with split debug info to handle symbols...
flutter build appbundle --release --split-debug-info=debug_symbols

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ AAB BUILD SUCCESSFUL!
    echo Copying AAB to main directory...
    copy "build\app\outputs\bundle\release\app-release.aab" "C:\Users\Cody Vincent\Desktop\Food Truck App\food-truck-CLOUD-BACKEND-AAB-v1.42.0.aab"
    echo AAB file location: C:\Users\Cody Vincent\Desktop\Food Truck App\food-truck-CLOUD-BACKEND-AAB-v1.42.0.aab
    echo.
    echo You can now upload this AAB to Google Play Console for testing!
) else (
    echo.
    echo ❌ AAB BUILD FAILED!
    echo Check the error messages above.
)

pause 
@echo off
echo Building Food Truck App AAB Bundle for Cloud Backend (v1.42.0)...
echo.

REM Set the project directory without spaces in the path
set "PROJECT_DIR=C:\Users\Cody Vincent\Desktop\Food Truck App\food_truck_mobile"

REM Change to project directory
cd /d "%PROJECT_DIR%"

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building AAB bundle with path fix...
REM Use subst to create a temporary drive mapping to avoid spaces
subst Z: "%PROJECT_DIR%"
cd /d Z:\

echo Building from Z: drive to avoid path spaces...
flutter build appbundle --release

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

REM Clean up the temporary drive mapping
subst Z: /d

pause 
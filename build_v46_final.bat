@echo off
echo Building Food Truck App v1.46.0...
echo Current directory: %CD%

REM Navigate to the Flutter mobile app directory
cd /d "D:\Food Truck App\food_truck_mobile"

echo Cleaning Flutter cache...
call flutter clean

echo Getting dependencies...
call flutter pub get

echo Building Android App Bundle (Release)...
call flutter build appbundle --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================
    echo ✅ BUILD SUCCESSFUL!
    echo ===============================================
    echo Built: food-truck-AUTO-SCHEDULE-v1.46.0.aab
    echo Location: D:\Food Truck App\food_truck_mobile\build\app\outputs\bundle\release\
    echo Size: 
    for %%f in ("build\app\outputs\bundle\release\app-release.aab") do echo %%~zf bytes
    echo.
    
    REM Copy and rename the built file
    copy "build\app\outputs\bundle\release\app-release.aab" "..\food-truck-AUTO-SCHEDULE-v1.46.0.aab"
    echo File copied to: D:\Food Truck App\food-truck-AUTO-SCHEDULE-v1.46.0.aab
) else (
    echo.
    echo ===============================================
    echo ❌ BUILD FAILED!
    echo ===============================================
    echo Error code: %ERRORLEVEL%
    echo Check the output above for details.
)

echo.
echo Press any key to exit...
pause 
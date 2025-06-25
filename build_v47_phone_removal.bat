@echo off
echo Building Food Truck App v1.47.0 - Phone Number Removal Update...
echo Current directory: %CD%

REM Navigate to the Flutter mobile app directory
cd /d "%CD%\food_truck_mobile"

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
    echo Built: food-truck-PHONE-REMOVAL-v1.47.0.aab
    echo Location: %CD%\build\app\outputs\bundle\release\
    echo Size: 
    for %%f in ("build\app\outputs\bundle\release\app-release.aab") do echo %%~zf bytes
    echo.
    
    REM Copy and rename the built file
    copy "build\app\outputs\bundle\release\app-release.aab" "..\food-truck-PHONE-REMOVAL-v1.47.0.aab"
    echo File copied to: %CD%\..\food-truck-PHONE-REMOVAL-v1.47.0.aab
    
    echo.
    echo ===============================================
    echo 📱 WHAT'S NEW IN v1.47.0:
    echo ===============================================
    echo ✅ Removed phone number requirements from registration
    echo ✅ Removed phone number fields from user profiles  
    echo ✅ Removed phone calling functionality
    echo ✅ Updated backend to use MongoDB Atlas (persistent storage)
    echo ✅ Fixed data persistence issues on Render
    echo ===============================================
) else (
    echo.
    echo ===============================================
    echo ❌ BUILD FAILED!
    echo ===============================================
    echo Error code: %ERRORLEVEL%
    echo Check the output above for details.
    echo.
    echo Common fixes:
    echo 1. Check internet connection for Gradle dependencies
    echo 2. Clear Gradle cache: gradle --stop, then delete .gradle folder
    echo 3. Run: flutter doctor to check setup
)

echo.
echo Press any key to exit...
pause 
@echo off
echo Building Food Truck App with Favorites Feature...
echo.

cd /d "C:\Users\Cody Vincent\Desktop\Food Truck App\food_truck_mobile"

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building AAB bundle...
flutter build appbundle --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ BUILD SUCCESSFUL!
    echo AAB file location: build\app\outputs\bundle\release\app-release.aab
    echo.
    echo You can now install this AAB for testing the favorites feature!
) else (
    echo.
    echo ❌ BUILD FAILED!
    echo Check the error messages above.
)

pause 
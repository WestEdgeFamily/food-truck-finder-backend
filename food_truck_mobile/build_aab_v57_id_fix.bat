@echo off
echo Building Food Truck App v1.57.0 - ID Fix for Truck Updates
echo ========================================================

cd /d "%~dp0"

echo.
echo Cleaning previous build...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo Building AAB for Android...
flutter build appbundle --release

echo.
echo Build completed!
echo AAB file location: build/app/outputs/bundle/release/app-release.aab
echo.
echo Version: 1.57.0
echo Changes: Fixed truck ID handling for updates (menu, schedule, location)
echo.
pause 
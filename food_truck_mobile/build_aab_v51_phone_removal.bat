@echo off
echo ================================
echo Building Food Truck App v1.51.0
echo Phone Permissions REMOVED
echo ================================

echo.
echo Cleaning project...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo Building AAB bundle...
flutter build appbundle --release

echo.
echo ================================
echo Build Complete!
echo Output: build\app\outputs\bundle\release\app-release.aab
echo ================================
pause 
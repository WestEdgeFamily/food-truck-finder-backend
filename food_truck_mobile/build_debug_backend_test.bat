@echo off
echo ================================
echo Building Food Truck App v1.51.0
echo DEBUG BUILD - Backend Testing
echo ================================

echo.
echo Cleaning project...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo Building debug APK...
flutter build apk --debug

echo.
echo ================================
echo Debug Build Complete!
echo Output: build\app\outputs\flutter-apk\app-debug.apk
echo This build includes enhanced backend debugging
echo ================================
pause 
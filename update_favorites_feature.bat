@echo off
echo ======================================
echo   Updating Food Truck App - Favorites Feature
echo ======================================
echo.

cd food_truck_mobile

echo [1/4] Cleaning previous build...
flutter clean

echo.
echo [2/4] Getting dependencies...
flutter pub get

echo.
echo [3/4] Building APK...
flutter build apk --release

echo.
echo [4/4] Build complete!
echo.
echo ======================================
echo   FAVORITE TRUCKS NOTIFICATION FEATURE
echo ======================================
echo.
echo New features added:
echo - Location-based notifications for favorite food trucks
echo - Customizable notification radius (1-50 miles)
echo - Background location monitoring every 5 minutes
echo - Smart notification management (no spam)
echo - Manual check button in settings
echo.
echo How to test:
echo 1. Install the new APK
echo 2. Grant location and notification permissions
echo 3. Add some food trucks to favorites
echo 4. Go to Settings and enable all notification options
echo 5. Set a small notification radius (1-2 miles)
echo 6. Use "Check Now" button to test manually
echo.
echo APK location: food_truck_mobile\build\app\outputs\flutter-apk\app-release.apk
echo.
pause 
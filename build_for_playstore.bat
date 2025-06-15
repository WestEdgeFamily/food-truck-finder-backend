@echo off
echo ======================================
echo   Building Food Truck App for Play Store
echo   FAVORITES NOTIFICATION FEATURE v1.6.1
echo ======================================
echo.

cd food_truck_mobile

echo [1/5] Cleaning previous build...
flutter clean

echo.
echo [2/5] Getting dependencies...
flutter pub get

echo.
echo [3/5] Building Android App Bundle for Play Store...
flutter build appbundle --release

echo.
echo [4/5] Building APK for testing...
flutter build apk --release

echo.
echo [5/5] Build complete!
echo.
echo ======================================
echo   FILES READY FOR DEPLOYMENT
echo ======================================
echo.
echo PLAY STORE DEPLOYMENT:
echo AAB File: food_truck_mobile\build\app\outputs\bundle\release\app-release.aab
echo.
echo TESTING:
echo APK File: food_truck_mobile\build\app\outputs\flutter-apk\app-release.apk
echo.
echo ======================================
echo   NEW FEATURES IN THIS VERSION
echo ======================================
echo.
echo ✅ Favorite Food Trucks Notifications
echo ✅ Location-based alerts (1-50 mile radius)
echo ✅ Background location monitoring
echo ✅ Smart notification management
echo ✅ Manual check functionality
echo ✅ Enhanced settings screen
echo.
echo VERSION: 1.6.1+9 (as set in pubspec.yaml)
echo.
echo Ready to upload to Google Play Console!
echo.
pause 
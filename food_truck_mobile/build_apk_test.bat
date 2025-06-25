@echo off
echo Building Food Truck App APK for Favorites Testing...
echo.

cd /d "C:\Users\Cody Vincent\Desktop\Food Truck App\food_truck_mobile"

echo Building APK...
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ APK BUILD SUCCESSFUL!
    echo APK file location: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo You can now install this APK on your Android device to test favorites!
    echo Use: adb install build\app\outputs\flutter-apk\app-release.apk
) else (
    echo.
    echo ❌ APK BUILD FAILED!
    echo Check the error messages above.
)

pause 
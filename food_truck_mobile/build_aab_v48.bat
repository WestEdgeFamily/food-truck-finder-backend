@echo off
echo Building Food Truck App v1.48.0 AAB Bundle...
echo.

REM Set environment variables to handle spaces in paths
set "FLUTTER_ROOT=D:\src\flutter"
set "ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk"
set "GRADLE_USER_HOME=C:\gradle-cache"

REM Create gradle cache directory if it doesn't exist
if not exist "C:\gradle-cache" mkdir "C:\gradle-cache"

REM Clean and get dependencies
echo Cleaning project...
flutter clean
echo.

echo Getting dependencies...
flutter pub get
echo.

REM Build the AAB
echo Building AAB bundle...
flutter build appbundle --release --build-name=1.48.0 --build-number=48

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build successful!
    echo AAB file location: build\app\outputs\bundle\release\app-release.aab
    echo.
    echo Copying AAB to parent directory...
    copy "build\app\outputs\bundle\release\app-release.aab" "..\food-truck-EMAIL-CONTACT-BUILT-v1.48.0.aab"
    echo.
    echo ✅ AAB bundle ready: food-truck-EMAIL-CONTACT-BUILT-v1.48.0.aab
) else (
    echo.
    echo ❌ Build failed with error code %ERRORLEVEL%
    echo Please check the error messages above.
)

pause 
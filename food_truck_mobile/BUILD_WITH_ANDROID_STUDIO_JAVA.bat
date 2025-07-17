@echo off
echo Using Android Studio's Java to build Food Truck App
echo ===================================================
echo.

:: Store the directory where this script is located
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo Current directory: %CD%
echo.

:: Set JAVA_HOME to Android Studio's bundled JDK
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

:: Verify Java is working
echo Checking Java installation...
"%JAVA_HOME%\bin\java" -version
if errorlevel 1 (
    echo ERROR: Could not find Java in Android Studio!
    echo Trying alternative location...
    set JAVA_HOME=C:\Program Files\Android\Android Studio\jre
    "%JAVA_HOME%\bin\java" -version
    if errorlevel 1 (
        echo ERROR: Java not found in Android Studio!
        echo Please check your Android Studio installation
        pause
        exit /b 1
    )
)

echo.
echo Java configured successfully!
echo JAVA_HOME=%JAVA_HOME%
echo.

:: Verify we're in the right directory
if not exist pubspec.yaml (
    echo ERROR: pubspec.yaml not found in current directory!
    echo Please run this script from the food_truck_mobile directory
    echo Current directory: %CD%
    pause
    exit /b 1
)

echo Starting clean build process...
echo.

:: Clean everything first
echo Step 1: Cleaning build artifacts...
call flutter clean
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q android\.gradle 2>nul
rmdir /s /q android\app\build 2>nul

:: Get dependencies
echo.
echo Step 2: Getting dependencies...
call flutter pub get

:: Build the app
echo.
echo Step 3: Building AAB bundle...
echo This may take 5-10 minutes...
call flutter build appbundle --release --no-tree-shake-icons --dart-define=API_URL=https://food-truck-finder-api.onrender.com/api

:: Check result
if exist build\app\outputs\bundle\release\app-release.aab (
    copy build\app\outputs\bundle\release\app-release.aab ..\food-truck-v2.2.1-build86.aab
    echo.
    echo ========================================
    echo BUILD SUCCESSFUL!
    echo AAB saved as: food-truck-v2.2.1-build86.aab
    echo ========================================
) else (
    echo.
    echo ========================================
    echo BUILD FAILED!
    echo Check the error messages above.
    echo ========================================
)

pause
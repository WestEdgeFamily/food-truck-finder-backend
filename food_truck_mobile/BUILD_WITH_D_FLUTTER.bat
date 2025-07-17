@echo off
echo Building Food Truck App with D: Drive Flutter
echo =============================================
echo.

:: Set Flutter to D: drive installation
set FLUTTER_DIR=D:\flutter
set PATH=%FLUTTER_DIR%\bin;%PATH%

:: Set Java from Android Studio
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

:: Navigate to project directory
cd /d "D:\CodingProjects\Food Truck App\food_truck_mobile"

echo Current directory: %CD%
echo Flutter location: %FLUTTER_DIR%
echo Java location: %JAVA_HOME%
echo.

:: Verify Flutter is accessible
where flutter >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found on D: drive!
    echo Please run INSTALL_FLUTTER_ON_D_DRIVE.bat first
    pause
    exit /b 1
)

:: Clean build artifacts
echo Cleaning build artifacts...
call flutter clean
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q android\.gradle 2>nul

:: Get dependencies
echo.
echo Getting dependencies...
call flutter pub get

:: Build AAB
echo.
echo Building AAB bundle (this may take 5-10 minutes)...
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
    echo Please check the error messages above.
    echo ========================================
)

pause
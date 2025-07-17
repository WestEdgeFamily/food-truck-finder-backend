@echo off
echo Building Food Truck App AAB Bundle - Cross Drive Fix (v1.75.0)...
echo.

REM Get the current directory
set "PROJECT_DIR=%~dp0"
echo Current directory: %PROJECT_DIR%

REM Clean any existing Z: drive mapping
subst Z: /d >nul 2>&1

REM Create temporary drive mapping for the entire project folder
echo Creating temporary Z: drive mapping...
subst Z: "%PROJECT_DIR%"

if %ERRORLEVEL% NEQ 0 (
    echo Failed to create drive mapping. Please run as Administrator.
    pause
    exit /b 1
)

REM Change to the mapped drive
cd /d Z:\

echo Working from mapped drive: %CD%
echo.

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

if %ERRORLEVEL% NEQ 0 (
    echo Dependencies failed to install.
    echo Cleaning up drive mapping...
    subst Z: /d
    pause
    exit /b 1
)

echo Building AAB bundle...
flutter build appbundle --release --no-tree-shake-icons

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ AAB BUILD SUCCESSFUL!
    echo.
    echo Copying AAB back to original location...
    copy "build\app\outputs\bundle\release\app-release.aab" "%PROJECT_DIR%food-truck-v1.74.0.aab"
    echo.
    echo AAB file location: %PROJECT_DIR%food-truck-v1.74.0.aab
    echo.
    echo You can now upload this AAB to Google Play Console!
) else (
    echo.
    echo ❌ AAB BUILD FAILED!
    echo Check the error messages above.
)

echo.
echo Cleaning up temporary drive mapping...
cd /d "%PROJECT_DIR%"
subst Z: /d

pause 
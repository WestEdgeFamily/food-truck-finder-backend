@echo off
echo Setting up Java environment and building Food Truck App
echo ========================================================
echo.

:: Common Java installation paths - modify if your Java is elsewhere
set JAVA_PATHS="C:\Program Files\Java\jdk-17" "C:\Program Files\Java\jdk-11" "C:\Program Files\OpenJDK\jdk-17" "C:\Program Files\Microsoft\jdk-17" "C:\Program Files\Eclipse Adoptium\jdk-17"

:: Try to find Java automatically
set JAVA_FOUND=false
for %%p in (%JAVA_PATHS%) do (
    if exist %%p (
        set JAVA_HOME=%%~p
        set JAVA_FOUND=true
        goto :java_found
    )
)

:java_found
if "%JAVA_FOUND%"=="false" (
    echo ERROR: Could not find Java installation!
    echo.
    echo Please install Java JDK from: https://adoptium.net/
    echo Or set JAVA_HOME manually:
    echo   set JAVA_HOME=C:\Path\To\Your\Java\JDK
    echo.
    pause
    exit /b 1
)

echo Found Java at: %JAVA_HOME%
echo.

:: Add Java to PATH
set PATH=%JAVA_HOME%\bin;%PATH%

:: Verify Java is working
java -version
if errorlevel 1 (
    echo ERROR: Java not working properly!
    pause
    exit /b 1
)

echo.
echo Java is configured successfully!
echo.
echo Starting build process...
echo.

:: Clean everything first
echo Step 1: Cleaning all caches...
call flutter clean
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul
rmdir /s /q .gradle 2>nul
rmdir /s /q android\.gradle 2>nul
rmdir /s /q android\app\build 2>nul
del /q .flutter-plugins 2>nul
del /q .flutter-plugins-dependencies 2>nul

:: Kill any Kotlin daemon processes
echo.
echo Step 2: Stopping Kotlin daemons...
taskkill /f /im java.exe /fi "WINDOWTITLE eq kotlin*" 2>nul
timeout /t 2 /nobreak >nul

:: Clear user-level Gradle cache
echo.
echo Step 3: Clearing user Gradle cache...
if exist "%USERPROFILE%\.gradle\caches" (
    for /d %%d in ("%USERPROFILE%\.gradle\caches\*kotlin*") do rmdir /s /q "%%d" 2>nul
)

:: Get dependencies
echo.
echo Step 4: Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)

:: Build the app
echo.
echo Step 5: Building AAB (this will take several minutes)...
set FLUTTER_BUILD_MODE=release
call flutter build appbundle --release --no-tree-shake-icons --dart-define=API_URL=https://food-truck-finder-api.onrender.com/api

:: Check if build succeeded
if exist build\app\outputs\bundle\release\app-release.aab (
    copy build\app\outputs\bundle\release\app-release.aab ..\food-truck-v2.2.1-build86.aab
    echo.
    echo ==========================================
    echo BUILD SUCCESSFUL!
    echo AAB saved as: food-truck-v2.2.1-build86.aab
    echo ==========================================
    echo.
    echo Next steps:
    echo 1. Upload the AAB to Google Play Console
    echo 2. The backend is already deployed
    echo 3. Test the app after publishing
) else (
    echo.
    echo ==========================================
    echo BUILD FAILED!
    echo.
    echo If you continue to have issues:
    echo 1. Move your project to C: drive
    echo 2. Run as Administrator
    echo 3. Make sure Android SDK is up to date
    echo ==========================================
)

pause
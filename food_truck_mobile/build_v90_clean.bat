@echo off
echo "Building Food Truck App v2.2.1 (Version Code 90)"
echo "==================================================="

cd /d "D:\CodingProjects\Food Truck App\food_truck_mobile"

echo "Step 1: Cleaning Flutter project..."
call flutter clean
if errorlevel 1 (
    echo "Error: Flutter clean failed"
    pause
    exit /b 1
)

echo "Step 2: Getting Flutter dependencies..."
call flutter pub get
if errorlevel 1 (
    echo "Error: Flutter pub get failed"
    pause
    exit /b 1
)

echo "Step 3: Cleaning Android build..."
cd android
call gradlew clean
if errorlevel 1 (
    echo "Error: Gradle clean failed"
    pause
    exit /b 1
)
cd ..

echo "Step 4: Building AAB (Release)..."
call flutter build appbundle --release
if errorlevel 1 (
    echo "Error: Flutter build failed"
    pause
    exit /b 1
)

echo "==================================================="
echo "Build completed successfully!"
echo "AAB file location: build\app\outputs\bundle\release\app-release.aab"
echo "Version Code: 90"
echo "Version Name: 2.2.1"
echo "==================================================="

pause
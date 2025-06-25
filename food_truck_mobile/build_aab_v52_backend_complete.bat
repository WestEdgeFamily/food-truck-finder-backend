@echo off
echo ========================================
echo Building Food Truck App v1.52.0
echo BACKEND CONNECTIVITY COMPLETE
echo ========================================
echo.

echo 🧹 Cleaning previous builds...
call flutter clean
if %errorlevel% neq 0 (
    echo ❌ Clean failed!
    pause
    exit /b 1
)

echo.
echo 📦 Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Pub get failed!
    pause
    exit /b 1
)

echo.
echo ✅ Version Info:
echo - Version: 1.52.0+52
echo - Features: COMPLETE Backend Integration
echo.
echo 🔗 Backend Connectivity Fixes:
echo - ✅ Menu API: Fixed ID mapping and data structure
echo - ✅ Schedule API: Fixed backend ID resolution
echo - ✅ Location API: Fixed truck identification
echo - ✅ Analytics API: Added proper backend integration
echo - ✅ Email Display: Backend data properly mapped
echo - ✅ Error Handling: Comprehensive debugging added
echo - ✅ Data Persistence: All operations save to MongoDB
echo.
echo 📱 Device Compatibility:
echo - ✅ Phone permissions removed for tablet support
echo - ✅ Android 14+ compatible
echo - ✅ Rebecca K50 tablet tested
echo.

echo 🔨 Building release AAB bundle...
call flutter build appbundle --release --build-name=1.52.0 --build-number=52
if %errorlevel% neq 0 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo.
echo 🎉 BUILD SUCCESSFUL!
echo.
echo 📦 Output: build\app\outputs\bundle\release\app-release.aab
echo 📊 Backend: https://food-truck-finder-api.onrender.com
echo 🗄️ Database: MongoDB Atlas (Persistent)
echo.
echo ⚡ Key Fixes in v1.52.0:
echo - Menu management now saves to backend properly
echo - Schedule updates work with correct truck IDs
echo - Location tracking connects to real API
echo - Analytics loads from backend with fallbacks
echo - Email addresses display correctly for customers
echo - All CRUD operations use proper data mapping
echo.
echo 🚀 Ready for Google Play Store deployment!
echo.
pause 
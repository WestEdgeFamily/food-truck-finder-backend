@echo off
echo Simple AAB Build Commands for Food Truck App v1.42.0
echo =====================================================
echo.
echo Run these commands one by one in PowerShell:
echo.
echo 1. cd "C:\Users\Cody Vincent\Desktop\Food Truck App\food_truck_mobile"
echo 2. flutter clean
echo 3. flutter pub get
echo 4. flutter build appbundle --release --split-debug-info=debug_symbols
echo.
echo If step 4 fails with debug symbols error, try:
echo 4a. flutter build appbundle --release --no-tree-shake-icons
echo.
echo Or try building from a path without spaces:
echo 5. robocopy "." "C:\temp_flutter_build" /E
echo 6. cd C:\temp_flutter_build
echo 7. flutter clean
echo 8. flutter pub get  
echo 9. flutter build appbundle --release
echo.
echo The AAB file will be in: build\app\outputs\bundle\release\app-release.aab
echo.
pause 
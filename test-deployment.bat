@echo off
echo Testing Food Truck API Deployment
echo ====================================
echo.

REM Replace YOUR_RENDER_URL with your actual URL from Render dashboard
set API_URL=https://YOUR_RENDER_URL.onrender.com

echo Testing Health Check...
curl %API_URL%/api/health
echo.
echo.

echo Testing Food Trucks Endpoint...
curl %API_URL%/api/trucks
echo.
echo.

echo Testing Complete!
echo.
echo If you see JSON responses above, your API is working!
echo Update your Flutter app with: %API_URL%/api
pause 
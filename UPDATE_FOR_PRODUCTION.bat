@echo off
echo ==========================================
echo Food Truck App - Production Update Script
echo ==========================================
echo.

echo This script will help you prepare your app for deployment.
echo.

set /p NETLIFY_URL="Enter your Netlify URL (e.g., https://my-app.netlify.app): "
set /p RENDER_URL="Enter your Render URL (e.g., https://my-backend.onrender.com): "

echo.
echo Updating backend CORS settings...

REM Update server.js CORS settings
powershell -Command "(Get-Content 'backend\src\server.js') -replace 'https://food-truck-finder.netlify.app', '%NETLIFY_URL%' | Set-Content 'backend\src\server.js'"

echo CORS settings updated!
echo.

echo ==========================================
echo NEXT STEPS:
echo ==========================================
echo.
echo 1. Commit and push to GitHub:
echo    cd backend
echo    git add -A
echo    git commit -m "Update CORS for production deployment"
echo    git push origin main
echo.
echo 2. Set environment variables in Render:
echo    MONGO_URI = your-mongodb-connection-string
echo    JWT_SECRET = your-secure-secret-key
echo    FRONTEND_URL = %NETLIFY_URL%
echo.
echo 3. Set environment variables in Netlify:
echo    REACT_APP_API_URL = %RENDER_URL%
echo    REACT_APP_WEBSOCKET_URL = %RENDER_URL%
echo.
echo 4. Trigger redeploy on both Render and Netlify
echo.
pause 
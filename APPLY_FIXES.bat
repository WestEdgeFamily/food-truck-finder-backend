@echo off
echo ========================================
echo Food Truck App - Authentication Fix Script
echo ========================================
echo.

REM Create backup directory
echo Creating backup of original files...
mkdir backend\backup_before_fix 2>nul

REM Backup original files
copy "backend\src\middleware\authMiddleware.js" "backend\backup_before_fix\authMiddleware.js.bak" >nul 2>&1
copy "backend\src\routes\events.js" "backend\backup_before_fix\events.js.bak" >nul 2>&1
copy "backend\src\routes\foodTrucks.js" "backend\backup_before_fix\foodTrucks.js.bak" >nul 2>&1

echo Backup completed!
echo.

REM Check if .env exists
if not exist "backend\.env" (
    echo Creating .env file...
    (
        echo # MongoDB Connection
        echo MONGO_URI=mongodb://localhost:27017/food-truck-tracker
        echo MONGODB_URI=mongodb://localhost:27017/food-truck-tracker
        echo.
        echo # JWT Secret Key
        echo JWT_SECRET=your_jwt_secret_key_here
        echo.
        echo # Server Port
        echo PORT=3001
        echo.
        echo # Frontend URL ^(for CORS^)
        echo FRONTEND_URL=http://localhost:3000
        echo.
        echo # Node Environment
        echo NODE_ENV=development
    ) > backend\.env
    echo .env file created!
) else (
    echo .env file already exists, skipping...
)

echo.
echo ========================================
echo IMPORTANT: The authentication fixes have been committed to Git.
echo.
echo To apply the fixes, please run:
echo   1. cd backend
echo   2. git pull   (if working with a remote repository)
echo   3. npm start
echo.
echo For the frontend:
echo   1. Open a new terminal
echo   2. cd web-portal
echo   3. npm start
echo ========================================
echo.
echo The following files were fixed:
echo - authMiddleware.js (JWT token consistency)
echo - events.js (auth middleware imports)
echo - foodTrucks.js (user ID references)
echo.
pause 
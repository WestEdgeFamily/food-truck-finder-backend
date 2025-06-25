@echo off
echo ========================================
echo  Army Of One Creator - Setup Script
echo ========================================
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from https://nodejs.org
    pause
    exit /b 1
)

echo Node.js detected. Installing dependencies...
echo.

REM Install dependencies
npm install

echo.
echo Setting up environment file...
if not exist .env (
    copy env.example .env
    echo Created .env file from template
) else (
    echo .env file already exists
)

echo.
echo Creating required directories...
if not exist recordings mkdir recordings
if not exist data mkdir data
if not exist temp mkdir temp
if not exist "assets\icons" mkdir "assets\icons"

echo.
echo ========================================
echo Setup complete! 
echo ========================================
echo.
echo To start the application:
echo   npm run dev
echo.
echo Don't forget to:
echo 1. Connect your USB cameras
echo 2. Edit .env file with your OpenAI API key (optional)
echo 3. Configure settings in the app
echo.
pause 
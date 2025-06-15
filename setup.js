const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Create necessary directories
const dirs = [
  'backend',
  'backend/src',
  'backend/src/models',
  'backend/src/routes',
  'backend/src/controllers',
  'backend/src/middleware',
  'backend/scripts',
  'web-portal',
  'web-portal/src',
  'web-portal/src/components',
  'web-portal/src/config'
];

dirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
    console.log(`Created directory: ${dir}`);
  }
});

// Create .env file
const envContent = `MONGODB_URI=mongodb://localhost:27017/foodtruck
JWT_SECRET=foodtruck_app_secret_key_2024
PORT=3001
NODE_ENV=development`;

fs.writeFileSync('backend/.env', envContent);
console.log('Created backend/.env file');

// Create package.json for backend
const backendPackageJson = {
  "name": "food-truck-app-backend",
  "version": "1.0.0",
  "description": "Backend for Food Truck App",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "seed": "node scripts/seed-utah-trucks.js && node scripts/seed-test-customer.js"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.0",
    "mongoose": "^7.0.3",
    "multer": "^1.4.5-lts.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
};

fs.writeFileSync('backend/package.json', JSON.stringify(backendPackageJson, null, 2));
console.log('Created backend/package.json');

// Create package.json for web-portal
const webPortalPackageJson = {
  "name": "food-truck-app-web",
  "version": "1.0.0",
  "description": "Web Portal for Food Truck App",
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "dependencies": {
    "@emotion/react": "^11.10.6",
    "@emotion/styled": "^11.10.6",
    "@mui/icons-material": "^5.11.16",
    "@mui/material": "^5.12.1",
    "axios": "^1.3.5",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.10.0",
    "react-scripts": "5.0.1"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^5.16.5",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^13.5.0"
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
};

fs.writeFileSync('web-portal/package.json', JSON.stringify(webPortalPackageJson, null, 2));
console.log('Created web-portal/package.json');

// Create API config file
const apiConfig = `export const API_CONFIG = {
  BASE_URL: process.env.REACT_APP_API_URL || 'http://localhost:3001'
};`;

fs.writeFileSync('web-portal/src/config/api.js', apiConfig);
console.log('Created web-portal/src/config/api.js');

// Create .gitignore
const gitignoreContent = `# Dependencies
node_modules/
/.pnp
.pnp.js

# Testing
/coverage

# Production
/build
/dist

# Misc
.DS_Store
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDE
.vscode/
.idea/
*.swp
*.swo

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Capacitor
capacitor.config.json
android/
ios/
web-portal/android/
web-portal/ios/`;

fs.writeFileSync('.gitignore', gitignoreContent);
console.log('Created .gitignore');

console.log('\nSetup complete! Next steps:');
console.log('1. Install MongoDB if you haven\'t already');
console.log('2. Run these commands:');
console.log('   cd backend');
console.log('   npm install');
console.log('   npm run seed');
console.log('3. In a new terminal:');
console.log('   cd web-portal');
console.log('   npm install');
console.log('   npm start'); 
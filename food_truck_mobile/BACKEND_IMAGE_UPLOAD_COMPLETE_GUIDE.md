# Complete Backend Image Upload Implementation Guide

## Files You Need to Update/Create

### 1. Create the Cloudinary Config File
**Location:** `backend/config/cloudinary.js`

```javascript
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'food-trucks',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp']
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }
});

module.exports = { upload };
```

### 2. Update Your server.js File
**Location:** `backend/server.js`

I've created the complete updated file at: `food_truck_mobile/UPDATED_SERVER_WITH_IMAGE_UPLOAD.js`

The only changes are:
- Added import: `const { upload } = require('./config/cloudinary');` (line 31)
- Added upload route after the review routes (lines 2523-2558)

### 3. Create/Update .env File
**Location:** `backend/.env` (DO NOT commit this to GitHub)

Add these lines:
```
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_API_KEY=your_api_key_here
CLOUDINARY_API_SECRET=your_api_secret_here
```

### 4. Install Required Packages
Run these commands in your backend folder:
```bash
cd backend
npm install multer cloudinary multer-storage-cloudinary
```

## Getting Cloudinary Credentials

1. Go to https://cloudinary.com
2. Sign up for a free account
3. On your dashboard, you'll see:
   - Cloud Name (something like "dxxxxxxx")
   - API Key (a number)
   - API Secret (a long string)
4. Copy these values to your .env file

## Files to Push to GitHub

Push ONLY these files:
- `backend/server.js` (the updated one)
- `backend/config/cloudinary.js`
- `backend/package.json` (will be updated after npm install)

DO NOT push:
- `.env` file (keep it local only)

## Testing the Upload

Once deployed:
1. Open your app
2. Go to Truck Management
3. Click "Manage Photos"
4. Upload an image
5. It should upload to Cloudinary and update your food truck

## Complete File Locations Summary

```
backend/
  ├── config/
  │   └── cloudinary.js          <-- CREATE THIS
  ├── server.js                  <-- UPDATE THIS (use UPDATED_SERVER_WITH_IMAGE_UPLOAD.js)
  ├── package.json               <-- WILL BE UPDATED BY npm install
  └── .env                       <-- CREATE/UPDATE THIS (DO NOT PUSH TO GITHUB)
```

The complete updated server.js is available at:
`food_truck_mobile/UPDATED_SERVER_WITH_IMAGE_UPLOAD.js`

Just copy it to replace your `backend/server.js` file!
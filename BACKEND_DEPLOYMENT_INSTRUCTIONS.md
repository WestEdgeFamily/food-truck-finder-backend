# Backend Deployment Instructions for Favorites API

## Overview
You need to add the favorites functionality to your `food_truck_finder_backend` GitHub repository so Render can deploy it automatically.

## Files to Add/Update

### 1. Create New Route File
**Path:** `routes/favorites.js`
**Content:** Use the file I created in `backend_files/routes/favorites.js`

### 2. Update User Model
**Path:** `models/User.js`
**Action:** Add the `favorites` field to your existing User schema:
```javascript
// Add this to your existing User schema
favorites: [{
  type: mongoose.Schema.Types.ObjectId,
  ref: 'FoodTruck'
}],
```

### 3. Update Main Server File
**Path:** `server.js` or `app.js` or `index.js` (whatever your main file is called)
**Action:** Add these lines:
```javascript
// Add this with your other route imports
const favoritesRoutes = require('./routes/favorites');

// Add this with your other route registrations
app.use('/api/users', favoritesRoutes);
```

## Step-by-Step Deployment Process

### Step 1: Access Your GitHub Repository
1. Go to: `https://github.com/yourusername/food_truck_finder_backend`
2. Click "Code" → "Open with GitHub Desktop" or use web editor

### Step 2: Add Favorites Route File
1. Navigate to the `routes/` folder
2. Create a new file called `favorites.js`
3. Copy the entire content from `backend_files/routes/favorites.js`
4. Save the file

### Step 3: Update User Model
1. Open `models/User.js`
2. Find your user schema definition
3. Add the favorites field:
```javascript
const userSchema = new mongoose.Schema({
  // ... your existing fields ...
  
  // ADD THIS LINE:
  favorites: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'FoodTruck'
  }],
  
  // ... rest of your schema ...
});
```

### Step 4: Update Main Server File
1. Open your main server file (`server.js`, `app.js`, or `index.js`)
2. Find where you import other routes (probably near the top)
3. Add:
```javascript
const favoritesRoutes = require('./routes/favorites');
```
4. Find where you register routes (usually with `app.use()`)
5. Add:
```javascript
app.use('/api/users', favoritesRoutes);
```

### Step 5: Commit and Push Changes
```bash
git add .
git commit -m "Add favorites API endpoints for location notifications"
git push origin main
```

### Step 6: Verify Render Deployment
1. Go to your Render dashboard
2. Check that your service redeploys automatically
3. Wait for deployment to complete (usually 2-5 minutes)
4. Check the logs for any errors

## Testing the Deployment

### Test Endpoints with cURL:

```bash
# 1. Check if favorites feature is available
curl https://food-truck-finder-api.onrender.com/api/users/favorites/check

# 2. Test getting favorites (should return empty array initially)
curl https://food-truck-finder-api.onrender.com/api/users/user_1749785616229/favorites

# 3. Test adding a favorite (replace with real truck ID)
curl -X POST https://food-truck-finder-api.onrender.com/api/users/user_1749785616229/favorites/REAL_TRUCK_ID

# 4. Test checking if favorited
curl https://food-truck-finder-api.onrender.com/api/users/user_1749785616229/favorites/check/REAL_TRUCK_ID
```

### Expected Results:
- **Endpoint 1:** Should return `{"available": true}`
- **Endpoint 2:** Should return `[]` (empty array) initially
- **Endpoint 3:** Should return `{"success": true, "message": "Added to favorites"}`
- **Endpoint 4:** Should return `{"isFavorite": true}`

## Troubleshooting

### If Render Build Fails:
1. Check Render logs for specific error messages
2. Make sure all file paths are correct
3. Verify that your User and FoodTruck models exist
4. Check that all required dependencies are in package.json

### If Endpoints Return 404:
1. Verify the route is properly registered in server.js
2. Check that the path `/api/users` is correct
3. Make sure the favorites.js file is in the routes/ folder

### If Database Errors Occur:
1. Verify your User model includes the favorites field
2. Check that FoodTruck model exists and is importable
3. Ensure MongoDB connection is working

## What Happens After Deployment

1. ✅ **App will stop showing "Favorites feature is not available"**
2. ✅ **Users can add/remove food trucks from favorites**
3. ✅ **Location monitoring will start checking for nearby favorites**
4. ✅ **"Check Now" button will trigger real location notifications**
5. ✅ **Complete favorites + notifications system will work**

## Files Structure in Your Repo Should Look Like:
```
food_truck_finder_backend/
├── server.js (or app.js/index.js)
├── package.json
├── models/
│   ├── User.js (UPDATED with favorites field)
│   └── FoodTruck.js
├── routes/
│   ├── auth.js
│   ├── trucks.js
│   ├── owners.js
│   └── favorites.js (NEW FILE)
└── ... other files
```

Once you push these changes, Render will automatically redeploy your backend and your app's favorites + location notifications will work perfectly! 🚀 
# Quick Copy Guide for GitHub Repository

## 🚀 What You Need to Do

### 1. Copy This File to Your GitHub Repo
**Create:** `routes/favorites.js`
**Copy from:** `backend_files/routes/favorites.js` (in this folder)

### 2. Update Your Existing User Model
**Edit:** `models/User.js` in your GitHub repo
**Add this line to your schema:**
```javascript
favorites: [{
  type: mongoose.Schema.Types.ObjectId,
  ref: 'FoodTruck'
}],
```

### 3. Update Your Main Server File
**Edit:** `server.js` (or `app.js` or `index.js`) in your GitHub repo
**Add these 2 lines:**
```javascript
// With other route imports:
const favoritesRoutes = require('./routes/favorites');

// With other app.use() statements:
app.use('/api/users', favoritesRoutes);
```

## 📁 Files You Need

### NEW FILE: routes/favorites.js
```javascript
// Copy this ENTIRE file content to routes/favorites.js in your GitHub repo:
```
(Copy the entire content from `backend_files/routes/favorites.js`)

### EXISTING FILE: models/User.js
Add this field to your existing user schema:
```javascript
favorites: [{
  type: mongoose.Schema.Types.ObjectId,
  ref: 'FoodTruck'
}],
```

### EXISTING FILE: server.js (or app.js/index.js)
Add these imports and routes:
```javascript
const favoritesRoutes = require('./routes/favorites');
app.use('/api/users', favoritesRoutes);
```

## ⚡ Quick Steps
1. **Go to your GitHub repo:** `food_truck_finder_backend`
2. **Create:** `routes/favorites.js` with the content I provided
3. **Edit:** `models/User.js` - add the favorites field
4. **Edit:** `server.js` - add the 2 lines for routes
5. **Commit and push** changes
6. **Wait for Render** to redeploy (2-5 minutes)
7. **Test your app** - favorites should work!

## 🧪 Test Commands (after deployment)
```bash
# Should return {"available": true}
curl https://food-truck-finder-api.onrender.com/api/users/favorites/check

# Should return [] (empty array)
curl https://food-truck-finder-api.onrender.com/api/users/user_1749785616229/favorites
```

That's it! Once you make these changes and push to GitHub, Render will redeploy and your favorites + location notifications will work! 🎉 
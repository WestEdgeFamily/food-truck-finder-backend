# Backend API Endpoints for Favorites Feature

## Overview
Your app is trying to call these endpoints but they don't exist yet on your backend server at `https://food-truck-finder-api.onrender.com/api`

## Required Endpoints

### 1. Check Favorites Feature Availability
```http
GET /api/users/favorites/check
```
**Response:** `200 OK` (just needs to exist to signal feature is available)

### 2. Get User's Favorites
```http
GET /api/users/{userId}/favorites
```
**Response:**
```json
[
  {
    "_id": "truck_id_1",
    "name": "Taco Express",
    "businessName": "Taco Express LLC",
    "description": "Authentic Mexican street tacos",
    "ownerId": "owner_id",
    "cuisineTypes": ["Mexican", "Street Food"],
    "image": "https://example.com/image.jpg",
    "location": {
      "latitude": 40.7128,
      "longitude": -74.0060,
      "address": "123 Main St, New York, NY"
    },
    "rating": 4.5,
    "reviewCount": 89
  }
]
```

### 3. Add Favorite
```http
POST /api/users/{userId}/favorites/{truckId}
```
**Response:**
```json
{
  "success": true,
  "message": "Added to favorites"
}
```

### 4. Remove Favorite
```http
DELETE /api/users/{userId}/favorites/{truckId}
```
**Response:**
```json
{
  "success": true,
  "message": "Removed from favorites"
}
```

### 5. Check if Truck is Favorited
```http
GET /api/users/{userId}/favorites/check/{truckId}
```
**Response:**
```json
{
  "isFavorite": true
}
```

## Database Schema Needed

### Users Collection - Add Favorites Field
```javascript
{
  "_id": "user_id",
  "email": "user@example.com",
  "name": "User Name",
  "role": "customer",
  "favorites": ["truck_id_1", "truck_id_2", "truck_id_3"], // Array of truck IDs
  "createdAt": "2025-01-01T00:00:00.000Z"
}
```

## Sample Node.js/Express Implementation

### Route Handler (favorites.js)
```javascript
const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Your user model
const FoodTruck = require('../models/FoodTruck'); // Your food truck model

// Check if favorites feature is available
router.get('/favorites/check', (req, res) => {
  res.status(200).json({ available: true });
});

// Get user's favorites
router.get('/:userId/favorites', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get user with populated favorites
    const user = await User.findById(userId).populate('favorites');
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // If favorites is array of IDs, populate them
    let favorites = [];
    if (user.favorites && user.favorites.length > 0) {
      favorites = await FoodTruck.find({ '_id': { $in: user.favorites } });
    }
    
    res.json(favorites);
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({ error: 'Failed to get favorites' });
  }
});

// Add favorite
router.post('/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    // Check if truck exists
    const truck = await FoodTruck.findById(truckId);
    if (!truck) {
      return res.status(404).json({ error: 'Food truck not found' });
    }
    
    // Add to user's favorites (use $addToSet to avoid duplicates)
    const result = await User.findByIdAndUpdate(
      userId,
      { $addToSet: { favorites: truckId } },
      { new: true }
    );
    
    if (!result) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ success: true, message: 'Added to favorites' });
  } catch (error) {
    console.error('Add favorite error:', error);
    res.status(500).json({ error: 'Failed to add favorite' });
  }
});

// Remove favorite
router.delete('/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    // Remove from user's favorites
    const result = await User.findByIdAndUpdate(
      userId,
      { $pull: { favorites: truckId } },
      { new: true }
    );
    
    if (!result) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ success: true, message: 'Removed from favorites' });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({ error: 'Failed to remove favorite' });
  }
});

// Check if truck is favorited
router.get('/:userId/favorites/check/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const isFavorite = user.favorites && user.favorites.includes(truckId);
    res.json({ isFavorite });
  } catch (error) {
    console.error('Check favorite error:', error);
    res.status(500).json({ error: 'Failed to check favorite' });
  }
});

module.exports = router;
```

### Update User Model Schema
```javascript
// In your User model file
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  name: { type: String, required: true },
  role: { type: String, enum: ['customer', 'owner'], required: true },
  favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: 'FoodTruck' }], // Add this line
  createdAt: { type: Date, default: Date.now }
});
```

### Add to Main App Routes
```javascript
// In your main app.js or server.js
const favoritesRoutes = require('./routes/favorites');
app.use('/api/users', favoritesRoutes);
```

## Testing the Endpoints

Once implemented, test with curl:

```bash
# Check feature availability
curl https://food-truck-finder-api.onrender.com/api/users/favorites/check

# Get favorites
curl https://food-truck-finder-api.onrender.com/api/users/user_1749785616229/favorites

# Add favorite
curl -X POST https://food-truck-finder-api.onrender.com/api/users/user_1749785616229/favorites/truck_id

# Check favorite
curl https://food-truck-finder-api.onrender.com/api/users/user_1749785616229/favorites/check/truck_id
```

## Next Steps

1. **Add the favorites routes** to your backend server
2. **Update your User model** to include favorites array
3. **Deploy the changes** to Render
4. **Test the app** - the favorites should start working
5. **The notification system will then work** because it depends on favorites

Once you implement these endpoints, your app's favorites and location notifications will work perfectly! 🚀 
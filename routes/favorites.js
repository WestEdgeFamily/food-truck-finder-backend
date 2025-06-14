const express = require('express');
const router = express.Router();
const User = require('../models/User');
const FoodTruck = require('../models/FoodTruck');

// Check if favorites feature is available
router.get('/favorites/check', (req, res) => {
  res.status(200).json({ available: true });
});

// Get user's favorites
router.get('/:userId/favorites', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`Getting favorites for user: ${userId}`);
    
    // Find user by ID
    const user = await User.findOne({ customUserId: userId });
    if (!user) {
      console.log(`User not found: ${userId}`);
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Get favorites - if no favorites field exists, return empty array
    const favoriteIds = user.favorites || [];
    console.log(`User has ${favoriteIds.length} favorite truck IDs`);
    
    // If no favorites, return empty array
    if (favoriteIds.length === 0) {
      return res.json([]);
    }
    
    // Get full truck data for each favorite
    const favorites = await FoodTruck.find({ '_id': { $in: favoriteIds } });
    console.log(`Found ${favorites.length} favorite trucks with full data`);
    
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
    console.log(`Adding favorite: User ${userId}, Truck ${truckId}`);
    
    // Check if truck exists
    const truck = await FoodTruck.findById(truckId);
    if (!truck) {
      console.log(`Food truck not found: ${truckId}`);
      return res.status(404).json({ error: 'Food truck not found' });
    }
    
    // Add to user's favorites (use $addToSet to avoid duplicates)
    const result = await User.findByIdAndUpdate(
      userId,
      { $addToSet: { favorites: truckId } },
      { new: true, upsert: false }
    );
    
    if (!result) {
      console.log(`User not found: ${userId}`);
      return res.status(404).json({ error: 'User not found' });
    }
    
    console.log(`Successfully added truck ${truckId} to user ${userId} favorites`);
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
    console.log(`Removing favorite: User ${userId}, Truck ${truckId}`);
    
    // Remove from user's favorites
    const result = await User.findByIdAndUpdate(
      userId,
      { $pull: { favorites: truckId } },
      { new: true }
    );
    
    if (!result) {
      console.log(`User not found: ${userId}`);
      return res.status(404).json({ error: 'User not found' });
    }
    
    console.log(`Successfully removed truck ${truckId} from user ${userId} favorites`);
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
    console.log(`Checking if truck ${truckId} is favorited by user ${userId}`);
    
    const user = await User.findById(userId);
    if (!user) {
      console.log(`User not found: ${userId}`);
      return res.status(404).json({ error: 'User not found' });
    }
    
    const isFavorite = user.favorites && user.favorites.includes(truckId);
    console.log(`Truck ${truckId} is ${isFavorite ? 'favorited' : 'not favorited'} by user ${userId}`);
    
    res.json({ isFavorite });
  } catch (error) {
    console.error('Check favorite error:', error);
    res.status(500).json({ error: 'Failed to check favorite' });
  }
});

module.exports = router; 

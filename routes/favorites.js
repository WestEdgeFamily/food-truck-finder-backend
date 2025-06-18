const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const User = require('../models/User');
const FoodTruck = require('../models/FoodTruck');
const Favorite = require('../models/Favorite');

// Check if favorites feature is available
router.get('/check', async (req, res) => {
  console.log('[FAVORITES] Checking favorites feature availability');
  try {
    res.json({ 
      available: true,
      message: 'Favorites feature is available',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('[FAVORITES] Error checking feature availability:', error);
    res.status(500).json({ 
      available: false, 
      error: 'Error checking favorites feature availability',
      details: error.message 
    });
  }
});

// Get user's favorites
router.get('/:userId', async (req, res) => {
  const { userId } = req.params;
  console.log(`[FAVORITES] Getting favorites for user: ${userId}`);
  
  try {
    // Find all favorites for this user
    const favorites = await Favorite.find({ userId });
    const favoriteIds = favorites.map(fav => fav.truckId);
    
    // Get the actual food truck data
    const favoriteTrucks = await FoodTruck.find({ id: { $in: favoriteIds } });
    
    console.log(`[FAVORITES] Found ${favoriteTrucks.length} favorites for user ${userId}`);
    
    res.json({
      favorites: favoriteTrucks,
      count: favoriteTrucks.length,
      userId: userId,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error(`[FAVORITES] Error getting favorites for user ${userId}:`, error);
    res.status(500).json({ 
      error: 'Error fetching favorites',
      details: error.message,
      userId: userId
    });
  }
});

// Add food truck to favorites
router.post('/:userId/:truckId', async (req, res) => {
  const { userId, truckId } = req.params;
  console.log(`[FAVORITES] Adding truck ${truckId} to favorites for user ${userId}`);
  
  try {
    // Check if food truck exists (using custom id field, not _id)
    const foodTruck = await FoodTruck.findOne({ id: truckId });
    if (!foodTruck) {
      console.log(`[FAVORITES] Food truck not found: ${truckId}`);
      return res.status(404).json({ error: 'Food truck not found' });
    }
    
    // Check if already in favorites
    const existingFavorite = await Favorite.findOne({ userId, truckId });
    if (existingFavorite) {
      console.log(`[FAVORITES] Truck ${truckId} already in favorites for user ${userId}`);
      return res.json({ 
        message: 'Food truck already in favorites',
        truckId: truckId,
        userId: userId,
        alreadyFavorited: true
      });
    }
    
    // Add to favorites
    const favorite = new Favorite({ userId, truckId });
    await favorite.save();
    
    // Get updated count
    const totalFavorites = await Favorite.countDocuments({ userId });
    
    console.log(`[FAVORITES] Successfully added truck ${truckId} to favorites for user ${userId}`);
    res.json({ 
      message: 'Food truck added to favorites',
      truckId: truckId,
      userId: userId,
      favoritesCount: totalFavorites,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error(`[FAVORITES] Error adding truck ${truckId} to favorites for user ${userId}:`, error);
    res.status(500).json({ 
      error: 'Error adding to favorites',
      details: error.message,
      userId: userId,
      truckId: truckId
    });
  }
});

// Remove food truck from favorites
router.delete('/:userId/:truckId', async (req, res) => {
  const { userId, truckId } = req.params;
  console.log(`[FAVORITES] Removing truck ${truckId} from favorites for user ${userId}`);
  
  try {
    // Remove from favorites
    const result = await Favorite.deleteOne({ userId, truckId });
    
    if (result.deletedCount === 0) {
      console.log(`[FAVORITES] Truck ${truckId} not in favorites for user ${userId}`);
      return res.json({ 
        message: 'Food truck not in favorites',
        truckId: truckId,
        userId: userId,
        wasInFavorites: false
      });
    }
    
    // Get updated count
    const totalFavorites = await Favorite.countDocuments({ userId });
    
    console.log(`[FAVORITES] Successfully removed truck ${truckId} from favorites for user ${userId}`);
    res.json({ 
      message: 'Food truck removed from favorites',
      truckId: truckId,
      userId: userId,
      favoritesCount: totalFavorites,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error(`[FAVORITES] Error removing truck ${truckId} from favorites for user ${userId}:`, error);
    res.status(500).json({ 
      error: 'Error removing from favorites',
      details: error.message,
      userId: userId,
      truckId: truckId
    });
  }
});

// Check if specific food truck is in user's favorites
router.get('/:userId/check/:truckId', async (req, res) => {
  const { userId, truckId } = req.params;
  console.log(`[FAVORITES] Checking if truck ${truckId} is favorited by user ${userId}`);
  
  try {
    // Check if favorite exists
    const favorite = await Favorite.findOne({ userId, truckId });
    const isFavorited = !!favorite;
    
    console.log(`[FAVORITES] Truck ${truckId} is ${isFavorited ? 'favorited' : 'not favorited'} by user ${userId}`);
    
    res.json({ 
      isFavorited: isFavorited,
      truckId: truckId,
      userId: userId,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error(`[FAVORITES] Error checking favorite status for truck ${truckId} and user ${userId}:`, error);
    res.status(500).json({ 
      error: 'Error checking favorite status',
      details: error.message,
      userId: userId,
      truckId: truckId
    });
  }
});

module.exports = router;

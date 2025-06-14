const express = require('express');
const router = express.Router();
const User = require('../models/User');
const FoodTruck = require('../models/FoodTruck');

// Helper function to find or create user with fallback logic
async function findOrCreateUser(userId) {
  console.log(`[FAVORITES] Looking up user with ID: ${userId}`);
  
  try {
    // First, try to find user by customUserId
    let user = await User.findOne({ customUserId: userId });
    
    if (user) {
      console.log(`[FAVORITES] Found user by customUserId: ${user.customUserId}`);
      return user;
    }
    
    console.log(`[FAVORITES] No user found with customUserId: ${userId}`);
    
    // Fallback: Check if this looks like an existing user without customUserId
    // Look for users without customUserId field and see if we can match by other criteria
    const usersWithoutCustomId = await User.find({ 
      $or: [
        { customUserId: { $exists: false } },
        { customUserId: null },
        { customUserId: '' }
      ]
    });
    
    if (usersWithoutCustomId.length > 0) {
      console.log(`[FAVORITES] Found ${usersWithoutCustomId.length} users without customUserId`);
      
      // For now, we'll take the first user without customUserId and assign this customUserId to them
      // In a real app, you might want more sophisticated matching logic
      const existingUser = usersWithoutCustomId[0];
      existingUser.customUserId = userId;
      
      // Initialize favorites array if it doesn't exist
      if (!existingUser.favorites) {
        existingUser.favorites = [];
      }
      
      await existingUser.save();
      console.log(`[FAVORITES] Updated existing user ${existingUser._id} with customUserId: ${userId}`);
      return existingUser;
    }
    
    // If no existing users to update, create a new user
    console.log(`[FAVORITES] Creating new user with customUserId: ${userId}`);
    user = new User({
      customUserId: userId,
      favorites: [],
      // Add default fields that might be required
      email: `${userId}@placeholder.com`, // Placeholder email
      name: `User ${userId}`,
      createdAt: new Date()
    });
    
    await user.save();
    console.log(`[FAVORITES] Created new user: ${user._id} with customUserId: ${userId}`);
    return user;
    
  } catch (error) {
    console.error(`[FAVORITES] Error in findOrCreateUser for ${userId}:`, error);
    throw error;
  }
}

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
    const user = await findOrCreateUser(userId);
    
    // Populate the favorites with actual food truck data
    const populatedUser = await User.findOne({ customUserId: userId })
      .populate('favorites', 'name description cuisine location rating imageUrl');
    
    if (!populatedUser) {
      console.log(`[FAVORITES] User not found after creation: ${userId}`);
      return res.status(404).json({ error: 'User not found' });
    }
    
    const favorites = populatedUser.favorites || [];
    console.log(`[FAVORITES] Found ${favorites.length} favorites for user ${userId}`);
    
    res.json({
      favorites: favorites,
      count: favorites.length,
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
    // Check if food truck exists
    const foodTruck = await FoodTruck.findById(truckId);
    if (!foodTruck) {
      console.log(`[FAVORITES] Food truck not found: ${truckId}`);
      return res.status(404).json({ error: 'Food truck not found' });
    }
    
    const user = await findOrCreateUser(userId);
    
    // Check if already in favorites
    if (user.favorites.includes(truckId)) {
      console.log(`[FAVORITES] Truck ${truckId} already in favorites for user ${userId}`);
      return res.json({ 
        message: 'Food truck already in favorites',
        truckId: truckId,
        userId: userId,
        alreadyFavorited: true
      });
    }
    
    // Add to favorites
    user.favorites.push(truckId);
    await user.save();
    
    console.log(`[FAVORITES] Successfully added truck ${truckId} to favorites for user ${userId}`);
    res.json({ 
      message: 'Food truck added to favorites',
      truckId: truckId,
      userId: userId,
      favoritesCount: user.favorites.length,
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
    const user = await findOrCreateUser(userId);
    
    // Check if in favorites
    const truckIndex = user.favorites.indexOf(truckId);
    if (truckIndex === -1) {
      console.log(`[FAVORITES] Truck ${truckId} not in favorites for user ${userId}`);
      return res.json({ 
        message: 'Food truck not in favorites',
        truckId: truckId,
        userId: userId,
        wasInFavorites: false
      });
    }
    
    // Remove from favorites
    user.favorites.splice(truckIndex, 1);
    await user.save();
    
    console.log(`[FAVORITES] Successfully removed truck ${truckId} from favorites for user ${userId}`);
    res.json({ 
      message: 'Food truck removed from favorites',
      truckId: truckId,
      userId: userId,
      favoritesCount: user.favorites.length,
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
    const user = await findOrCreateUser(userId);
    
    const isFavorited = user.favorites.includes(truckId);
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

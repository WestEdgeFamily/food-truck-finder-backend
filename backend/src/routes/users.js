const express = require('express');
const User = require('../models/User');
const FoodTruck = require('../models/FoodTruck');
const { protect } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');

const router = express.Router();

// Configure multer for avatar uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/avatars/');
  },
  filename: function (req, file, cb) {
    cb(null, `${req.user.id}-${Date.now()}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: function (req, file, cb) {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// @route   GET /api/users/profile
// @desc    Get current user profile
// @access  Private
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .populate('favorites.foodTrucks.truckId', 'name cuisineType location isActive averageRating')
      .select('-password');
    
    res.json(user);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Error fetching profile', error: error.message });
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', protect, async (req, res) => {
  try {
    const {
      name,
      phone,
      profile,
      preferences
    } = req.body;

    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Update basic info
    if (name) user.name = name;
    if (phone) user.phone = phone;
    
    // Update profile
    if (profile) {
      user.profile = { ...user.profile, ...profile };
    }
    
    // Update preferences
    if (preferences) {
      user.preferences = {
        notifications: { ...user.preferences.notifications, ...preferences.notifications },
        location: { ...user.preferences.location, ...preferences.location },
        display: { ...user.preferences.display, ...preferences.display }
      };
    }

    await user.save();
    
    const updatedUser = await User.findById(req.user.id)
      .populate('favorites.foodTrucks.truckId', 'name cuisineType location isActive averageRating')
      .select('-password');
    
    res.json({
      message: 'Profile updated successfully',
      user: updatedUser
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Error updating profile', error: error.message });
  }
});

// @route   POST /api/users/profile/avatar
// @desc    Upload user avatar
// @access  Private
router.post('/profile/avatar', protect, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const user = await User.findById(req.user.id);
    user.avatar = `/uploads/avatars/${req.file.filename}`;
    await user.save();

    res.json({
      message: 'Avatar uploaded successfully',
      avatar: user.avatar
    });
  } catch (error) {
    console.error('Avatar upload error:', error);
    res.status(500).json({ message: 'Error uploading avatar', error: error.message });
  }
});

// @route   GET /api/users/favorites
// @desc    Get user's favorite food trucks with full details
// @access  Private
router.get('/favorites', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .populate({
        path: 'favorites.foodTrucks.truckId',
        select: 'name description cuisineType location isActive averageRating menu businessHours images',
        populate: {
          path: 'owner',
          select: 'name email phone'
        }
      });

    const favorites = user.favorites.foodTrucks.map(fav => ({
      ...fav.truckId.toObject(),
      favoriteInfo: {
        addedDate: fav.addedDate,
        notes: fav.notes
      }
    }));

    res.json({
      favorites,
      totalCount: favorites.length,
      cuisinePreferences: user.favorites.cuisineTypes
    });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({ message: 'Error fetching favorites', error: error.message });
  }
});

// @route   POST /api/users/favorites/:truckId
// @desc    Add food truck to favorites
// @access  Private
router.post('/favorites/:truckId', protect, async (req, res) => {
  try {
    const { notes } = req.body;
    const truckId = req.params.truckId;

    // Verify truck exists
    const truck = await FoodTruck.findById(truckId);
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    const user = await User.findById(req.user.id);
    
    // Check if already favorited
    const alreadyFavorited = user.favorites.foodTrucks.find(
      fav => fav.truckId.toString() === truckId
    );

    if (alreadyFavorited) {
      return res.status(400).json({ message: 'Truck already in favorites' });
    }

    // Add to favorites
    await user.addFavorite(truckId, notes);

    // Emit WebSocket event
    const io = req.app.get('socketio');
    if (io) {
      io.to(`truck_${truckId}`).emit('favorite_added', {
        userId: user._id,
        userName: user.name,
        truckId: truckId,
        timestamp: new Date()
      });
    }

    res.json({
      message: 'Food truck added to favorites',
      truck: {
        id: truck._id,
        name: truck.name,
        addedDate: new Date()
      }
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    res.status(500).json({ message: 'Error adding to favorites', error: error.message });
  }
});

// @route   DELETE /api/users/favorites/:truckId
// @desc    Remove food truck from favorites
// @access  Private
router.delete('/favorites/:truckId', protect, async (req, res) => {
  try {
    const truckId = req.params.truckId;
    const user = await User.findById(req.user.id);

    await user.removeFavorite(truckId);

    res.json({ message: 'Food truck removed from favorites' });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({ message: 'Error removing from favorites', error: error.message });
  }
});

// @route   GET /api/users/activity
// @desc    Get user activity and statistics
// @access  Private
router.get('/activity', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .populate('activity.trucksVisited.truckId', 'name cuisineType location')
      .select('activity preferences');

    const stats = {
      totalVisits: user.activity.totalVisits,
      lastLogin: user.activity.lastLogin,
      favoritesCount: user.favorites?.foodTrucks?.length || 0,
      trucksVisited: user.activity.trucksVisited.length,
      averageRating: user.activity.trucksVisited.reduce((sum, visit) => 
        sum + (visit.rating || 0), 0) / user.activity.trucksVisited.length || 0,
      recentSearches: user.activity.searchHistory.slice(0, 10),
      joinDate: user.createdAt
    };

    res.json({
      activity: user.activity,
      statistics: stats
    });
  } catch (error) {
    console.error('Get activity error:', error);
    res.status(500).json({ message: 'Error fetching activity', error: error.message });
  }
});

// @route   POST /api/users/activity/truck-visit
// @desc    Record truck visit with rating/review
// @access  Private
router.post('/activity/truck-visit', protect, async (req, res) => {
  try {
    const { truckId, rating, review } = req.body;

    // Verify truck exists
    const truck = await FoodTruck.findById(truckId);
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    const user = await User.findById(req.user.id);

    // Add visit to activity
    user.activity.trucksVisited.push({
      truckId,
      rating,
      review,
      visitDate: new Date()
    });

    await user.save();

    res.json({ message: 'Visit recorded successfully' });
  } catch (error) {
    console.error('Record visit error:', error);
    res.status(500).json({ message: 'Error recording visit', error: error.message });
  }
});

// @route   POST /api/users/activity/search
// @desc    Record search query
// @access  Private
router.post('/activity/search', protect, async (req, res) => {
  try {
    const { query } = req.body;
    
    if (!query || query.trim().length === 0) {
      return res.status(400).json({ message: 'Search query is required' });
    }

    const user = await User.findById(req.user.id);

    // Add search to history (keep last 50)
    user.activity.searchHistory.unshift({
      query: query.trim(),
      timestamp: new Date()
    });

    if (user.activity.searchHistory.length > 50) {
      user.activity.searchHistory = user.activity.searchHistory.slice(0, 50);
    }

    await user.save();

    res.json({ message: 'Search recorded' });
  } catch (error) {
    console.error('Record search error:', error);
    res.status(500).json({ message: 'Error recording search', error: error.message });
  }
});

// @route   GET /api/users/recommendations
// @desc    Get personalized food truck recommendations
// @access  Private
router.get('/recommendations', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .populate('favorites.foodTrucks.truckId', 'cuisineType');

    // Get user's favorite cuisine types
    const favoriteCuisines = user.favorites.foodTrucks.map(
      fav => fav.truckId.cuisineType
    );
    
    // Get favorite truck IDs to exclude from recommendations
    const favoriteTruckIds = user.getFavoriteTruckIds();

    // Find trucks with similar cuisine types
    const recommendations = await FoodTruck.find({
      _id: { $nin: favoriteTruckIds },
      cuisineType: { $in: favoriteCuisines },
      isActive: true,
      averageRating: { $gte: 3.5 }
    })
    .populate('owner', 'name')
    .limit(10)
    .sort({ averageRating: -1, createdAt: -1 });

    // If not enough recommendations, add highly rated trucks
    if (recommendations.length < 5) {
      const additionalTrucks = await FoodTruck.find({
        _id: { $nin: [...favoriteTruckIds, ...recommendations.map(r => r._id)] },
        isActive: true,
        averageRating: { $gte: 4.0 }
      })
      .populate('owner', 'name')
      .limit(5 - recommendations.length)
      .sort({ averageRating: -1 });

      recommendations.push(...additionalTrucks);
    }

    res.json({
      recommendations,
      reason: favoriteCuisines.length > 0 
        ? `Based on your favorite cuisines: ${favoriteCuisines.join(', ')}`
        : 'Highly rated food trucks in your area'
    });
  } catch (error) {
    console.error('Get recommendations error:', error);
    res.status(500).json({ message: 'Error getting recommendations', error: error.message });
  }
});

// @route   DELETE /api/users/account
// @desc    Delete user account
// @access  Private
router.delete('/account', protect, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user.id);
    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ message: 'Error deleting account', error: error.message });
  }
});

module.exports = router; 
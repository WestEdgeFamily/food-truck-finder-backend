const express = require('express');
const {
  createFoodTruck,
  getFoodTrucks,
  getFoodTruck,
  getMyTruck,
  updateFoodTruck,
  deleteFoodTruck,
  updateLocation,
  updateHours,
  updateFoodTypes,
  addRating,
  addMenuItem,
  deleteMenuItem,
  getFilters,
  searchFoodTrucks,
  // New social media tracking features
  reportLocation,
  updateSocialMedia,
  checkIn,
  adminUpdateLocation,
  getLocationHistory
} = require('../controllers/foodTruckController');
const { protect, authorize } = require('../middleware/auth');
const FoodTruck = require('../models/FoodTruck');

const router = express.Router();

// Public routes (no authentication required)
router.get('/', getFoodTrucks);
router.get('/search', searchFoodTrucks);
router.get('/filters', getFilters);
router.get('/:id', getFoodTruck);
router.get('/:id/location-history', getLocationHistory);

// Protected routes (authentication required)
router.use(protect);

// Owner routes
router.get('/my-truck', authorize('owner'), getMyTruck);
router.post('/', authorize('owner'), createFoodTruck);
router.put('/:id', authorize('owner'), updateFoodTruck);
router.delete('/:id', authorize('owner'), deleteFoodTruck);

// Location management routes
router.put('/:id/location', authorize('owner'), updateLocation);
router.put('/:id/hours', authorize('owner'), updateHours);
router.put('/:id/foodtypes', authorize('owner'), updateFoodTypes);

// Social media tracking routes
router.put('/my-truck/social-media', authorize('owner'), updateSocialMedia);
router.post('/my-truck/checkin', authorize('owner'), checkIn);

// Customer interaction routes
router.post('/:id/report-location', reportLocation); // Any authenticated user can report
router.post('/:id/rating', addRating);

// Menu management routes
router.post('/:id/menu', authorize('owner'), addMenuItem);
router.delete('/:id/menu/:itemId', authorize('owner'), deleteMenuItem);

// Admin routes (for manual social media tracking)
router.put('/:id/admin-location', adminUpdateLocation); // TODO: Add admin authorization

// Real-time GPS location update endpoint
router.put('/:id/live-location', protect, async (req, res) => {
  try {
    const { latitude, longitude, accuracy, heading, speed, address, city, state, notes } = req.body;
    
    const truck = await FoodTruck.findOne({ 
      _id: req.params.id, 
      owner: req.user._id 
    });
    
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Update location with GPS data
    const locationUpdate = {
      coordinates: [longitude, latitude],
      address: address || truck.location.address,
      city: city || truck.location.city,
      state: state || truck.location.state,
      lastUpdated: new Date(),
      source: 'live_gps',
      confidence: accuracy < 10 ? 'high' : accuracy < 50 ? 'medium' : 'low',
      notes: notes || `GPS accuracy: ${accuracy}m`
    };

    // Add GPS metadata
    if (accuracy) locationUpdate.gpsAccuracy = accuracy;
    if (heading !== undefined) locationUpdate.heading = heading;
    if (speed !== undefined) locationUpdate.speed = speed;

    truck.location = { ...truck.location, ...locationUpdate };

    // Add to location history
    const historyEntry = {
      ...locationUpdate,
      timestamp: new Date()
    };
    
    if (!truck.locationHistory) truck.locationHistory = [];
    truck.locationHistory.unshift(historyEntry);
    
    // Keep only last 100 entries
    if (truck.locationHistory.length > 100) {
      truck.locationHistory = truck.locationHistory.slice(0, 100);
    }

    await truck.save();

    // Emit real-time update via WebSocket
    const io = req.app.get('socketio');
    if (io) {
      io.to('customers').emit('truck_location_updated', {
        truckId: truck._id,
        location: truck.location,
        timestamp: new Date(),
        source: 'live_gps',
        truckName: truck.name
      });
    }

    res.json({ 
      message: 'Location updated successfully',
      location: truck.location,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Live location update error:', error);
    res.status(500).json({ message: 'Error updating location', error: error.message });
  }
});

// Start GPS tracking session
router.post('/:id/start-tracking', protect, async (req, res) => {
  try {
    const truck = await FoodTruck.findOne({ 
      _id: req.params.id, 
      owner: req.user._id 
    });
    
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Mark truck as actively being tracked
    truck.trackingSession = {
      isActive: true,
      startTime: new Date(),
      sessionId: `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    };

    await truck.save();

    // Notify customers that this truck is now live
    const io = req.app.get('socketio');
    if (io) {
      io.to('customers').emit('truck_live_tracking_started', {
        truckId: truck._id,
        truckName: truck.name,
        timestamp: new Date()
      });
    }

    res.json({ 
      message: 'GPS tracking started',
      sessionId: truck.trackingSession.sessionId
    });
  } catch (error) {
    console.error('Start tracking error:', error);
    res.status(500).json({ message: 'Error starting tracking', error: error.message });
  }
});

// Stop GPS tracking session
router.post('/:id/stop-tracking', protect, async (req, res) => {
  try {
    const truck = await FoodTruck.findOne({ 
      _id: req.params.id, 
      owner: req.user._id 
    });
    
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // End tracking session
    if (truck.trackingSession) {
      truck.trackingSession.isActive = false;
      truck.trackingSession.endTime = new Date();
    }

    await truck.save();

    // Notify customers that tracking has stopped
    const io = req.app.get('socketio');
    if (io) {
      io.to('customers').emit('truck_tracking_stopped', {
        truckId: truck._id,
        truckName: truck.name,
        timestamp: new Date()
      });
    }

    res.json({ message: 'GPS tracking stopped' });
  } catch (error) {
    console.error('Stop tracking error:', error);
    res.status(500).json({ message: 'Error stopping tracking', error: error.message });
  }
});

// Get nearby food trucks with enhanced filtering
router.get('/nearby', async (req, res) => {
  try {
    const { lat, lng, radius = 5000, cuisineType, isOpen, minRating } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    let query = {
      'location.coordinates': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          $maxDistance: parseInt(radius)
        }
      }
    };

    // Apply filters
    if (cuisineType && cuisineType !== 'all') {
      query.cuisineType = cuisineType;
    }
    
    if (isOpen === 'true') {
      query.isActive = true;
    }
    
    if (minRating) {
      query.averageRating = { $gte: parseFloat(minRating) };
    }

    const trucks = await FoodTruck.find(query)
      .populate('owner', 'name email')
      .limit(50)
      .sort({ 'location.lastUpdated': -1 });

    res.json(trucks);
  } catch (error) {
    console.error('Nearby trucks error:', error);
    res.status(500).json({ message: 'Error finding nearby trucks', error: error.message });
  }
});

module.exports = router; 
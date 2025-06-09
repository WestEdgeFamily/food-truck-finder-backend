const FoodTruck = require('../models/FoodTruck');
const User = require('../models/User');

// Get owner's food truck
exports.getMyTruck = async (req, res) => {
  try {
    console.log('Looking for truck with owner ID:', req.user?.userId || req.user?._id);
    const userId = req.user?.userId || req.user?._id;
    if (!userId) {
      return res.status(401).json({ message: 'User not authenticated' });
    }
    let foodTruck = await FoodTruck.findOne({ owner: userId });
    
          if (!foodTruck) {
        // Create a new food truck if one doesn't exist
        const user = await User.findById(userId);
        foodTruck = new FoodTruck({
          owner: userId,
        name: user.businessName || 'My Food Truck',
        businessName: user.businessName || 'My Food Truck',
        phoneNumber: user.phoneNumber || '',
        location: {
          type: 'Point',
          coordinates: [0, 0],
          address: '',
          city: '',
          state: '',
          source: 'manual',
          confidence: 'low'
        },
        cuisineType: 'American',
        foodTypes: [],
        businessHours: [],
        menu: [],
        isActive: false,
        socialMedia: {
          instagram: { autoTrack: false },
          facebook: { autoTrack: false },
          twitter: { autoTrack: false }
        },
        trackingPreferences: {
          allowCustomerReports: true,
          requireLocationVerification: false,
          autoPostToSocial: false
        }
      });
              await foodTruck.save();
        console.log('Created new food truck for owner:', userId);
    }
    
    res.json(foodTruck);
  } catch (error) {
    console.error('Get my truck error:', error);
    res.status(500).json({ message: 'Error fetching food truck details', error: error.message });
  }
};

// Create a new food truck
exports.createFoodTruck = async (req, res) => {
  try {
    const userId = req.user?.userId || req.user?._id;
    const foodTruck = new FoodTruck({
      ...req.body,
      owner: userId
    });
    await foodTruck.save();
    res.status(201).json(foodTruck);
  } catch (error) {
    console.error('Create food truck error:', error);
    res.status(500).json({ message: 'Error creating food truck', error: error.message });
  }
};

// Get all food trucks with optional filters
exports.getFoodTrucks = async (req, res) => {
  try {
    const { lat, lng, radius = 5000, cuisine } = req.query;
    
    let query = {};
    
    // Add location filter if coordinates are provided
    if (lat && lng) {
      query.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          $maxDistance: parseInt(radius)
        }
      };
    }

    // Add cuisine filter if provided
    if (cuisine) {
      query.cuisineType = cuisine;
    }

    const foodTrucks = await FoodTruck.find(query)
      .populate('owner', 'name email businessName')
      .sort('-createdAt');

    res.json(foodTrucks);
  } catch (error) {
    console.error('Get food trucks error:', error);
    res.status(500).json({ message: 'Error fetching food trucks', error: error.message });
  }
};

// Get a single food truck by ID
exports.getFoodTruck = async (req, res) => {
  try {
    const foodTruck = await FoodTruck.findById(req.params.id)
      .populate('owner', 'name email businessName');
    
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    res.json(foodTruck);
  } catch (error) {
    console.error('Get food truck error:', error);
    res.status(500).json({ message: 'Error fetching food truck', error: error.message });
  }
};

// Update food truck details
exports.updateFoodTruck = async (req, res) => {
  try {
    const userId = req.user?.userId || req.user?._id;
    const foodTruck = await FoodTruck.findOneAndUpdate(
      { _id: req.params.id, owner: userId },
      req.body,
      { new: true, runValidators: true }
    );

    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    res.json(foodTruck);
  } catch (error) {
    console.error('Update food truck error:', error);
    res.status(500).json({ message: 'Error updating food truck', error: error.message });
  }
};

// Delete food truck
exports.deleteFoodTruck = async (req, res) => {
  try {
    const userId = req.user?.userId || req.user?._id;
    const foodTruck = await FoodTruck.findOneAndDelete({
      _id: req.params.id,
      owner: userId
    });

    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    res.json({ message: 'Food truck deleted successfully' });
  } catch (error) {
    console.error('Delete food truck error:', error);
    res.status(500).json({ message: 'Error deleting food truck', error: error.message });
  }
};

// Update food truck location (Enhanced for social media tracking)
exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude, address, city, state, source, notes } = req.body;
    const userId = req.user?.userId || req.user?._id;

    console.log('updateLocation called with:', { latitude, longitude, userId, source });

    if (!userId) {
      return res.status(401).json({ message: 'User not authenticated' });
    }

    // Validate inputs
    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    let foodTruck = await FoodTruck.findOne({ owner: userId });
    
    if (!foodTruck) {
      // Create new food truck if one doesn't exist
      const user = await User.findById(userId);
      foodTruck = new FoodTruck({
        owner: userId,
        name: user.businessName || 'My Food Truck',
        businessName: user.businessName || 'My Food Truck',
        phoneNumber: user.phoneNumber || '',
        location: {
          type: 'Point',
          coordinates: [longitude, latitude],
          address: address || '',
          city: city || '',
          state: state || '',
          source: source || 'owner',
          confidence: 'high',
          notes: notes || '',
          lastUpdated: new Date()
        },
        cuisineType: 'American',
        foodTypes: [],
        businessHours: [],
        menu: [],
        isActive: false
      });
    } else {
      // Save current location to history before updating
      if (foodTruck.location && foodTruck.location.coordinates[0] !== 0 && foodTruck.location.coordinates[1] !== 0) {
        foodTruck.locationHistory.push({
          coordinates: foodTruck.location.coordinates,
          address: foodTruck.location.address,
          city: foodTruck.location.city,
          state: foodTruck.location.state,
          source: foodTruck.location.source,
          confidence: foodTruck.location.confidence,
          notes: foodTruck.location.notes,
          timestamp: foodTruck.location.lastUpdated
        });
      }

      // Update current location
      foodTruck.location = {
        type: 'Point',
        coordinates: [longitude, latitude],
        address: address || foodTruck.location.address || '',
        city: city || foodTruck.location.city || '',
        state: state || foodTruck.location.state || '',
        source: source || 'owner',
        confidence: 'high',
        notes: notes || '',
        lastUpdated: new Date()
      };
    }

    await foodTruck.save({ validateModifiedOnly: true });
    console.log('Location updated successfully for user:', userId);
    res.json({ message: 'Location updated successfully', foodTruck });
  } catch (error) {
    console.error('Update location error:', error);
    if (error.name === 'ValidationError') {
      res.status(400).json({ message: 'Invalid location data', error: error.message });
    } else if (error.name === 'CastError') {
      res.status(400).json({ message: 'Invalid data format', error: error.message });
    } else {
      res.status(500).json({ message: 'Error updating location', error: error.message });
    }
  }
};

// Customer reports food truck location
exports.reportLocation = async (req, res) => {
  try {
    const { latitude, longitude, address, city, state, notes } = req.body;
    const { id: truckId } = req.params;
    const userId = req.user?.userId || req.user?._id;

    console.log('Customer location report:', { truckId, latitude, longitude, userId });

    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    const foodTruck = await FoodTruck.findById(truckId);
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Check if customer reports are allowed
    if (!foodTruck.trackingPreferences.allowCustomerReports) {
      return res.status(403).json({ message: 'Customer location reports are not allowed for this truck' });
    }

    // Add to location history
    foodTruck.locationHistory.push({
      coordinates: [longitude, latitude],
      address: address || '',
      city: city || '',
      state: state || '',
      source: 'customer',
      confidence: 'medium',
      notes: notes || '',
      reportedBy: userId,
      timestamp: new Date()
    });

    // If verification is not required, update main location
    if (!foodTruck.trackingPreferences.requireLocationVerification) {
      // Save current location to history before updating
      if (foodTruck.location && foodTruck.location.coordinates[0] !== 0 && foodTruck.location.coordinates[1] !== 0) {
        foodTruck.locationHistory.push({
          coordinates: foodTruck.location.coordinates,
          address: foodTruck.location.address,
          city: foodTruck.location.city,
          state: foodTruck.location.state,
          source: foodTruck.location.source,
          confidence: foodTruck.location.confidence,
          notes: foodTruck.location.notes,
          timestamp: foodTruck.location.lastUpdated
        });
      }

      foodTruck.location = {
        type: 'Point',
        coordinates: [longitude, latitude],
        address: address || '',
        city: city || '',
        state: state || '',
        source: 'customer',
        confidence: 'medium',
        notes: notes || `Reported by customer`,
        lastUpdated: new Date()
      };
    }

    await foodTruck.save();
    res.json({ message: 'Location reported successfully', requiresVerification: foodTruck.trackingPreferences.requireLocationVerification });
  } catch (error) {
    console.error('Report location error:', error);
    res.status(500).json({ message: 'Error reporting location', error: error.message });
  }
};

// Update social media settings
exports.updateSocialMedia = async (req, res) => {
  try {
    const { instagram, facebook, twitter } = req.body;
    const userId = req.user?.userId || req.user?._id;

    const foodTruck = await FoodTruck.findOne({ owner: userId });
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    if (instagram) {
      foodTruck.socialMedia.instagram = {
        ...foodTruck.socialMedia.instagram,
        ...instagram
      };
    }

    if (facebook) {
      foodTruck.socialMedia.facebook = {
        ...foodTruck.socialMedia.facebook,
        ...facebook
      };
    }

    if (twitter) {
      foodTruck.socialMedia.twitter = {
        ...foodTruck.socialMedia.twitter,
        ...twitter
      };
    }

    await foodTruck.save();
    res.json({ message: 'Social media settings updated successfully', socialMedia: foodTruck.socialMedia });
  } catch (error) {
    console.error('Update social media error:', error);
    res.status(500).json({ message: 'Error updating social media settings', error: error.message });
  }
};

// Check-in feature for food truck owners
exports.checkIn = async (req, res) => {
  try {
    const { latitude, longitude, address, city, state, notes, autoPostToSocial } = req.body;
    const userId = req.user?.userId || req.user?._id;

    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    const foodTruck = await FoodTruck.findOne({ owner: userId });
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Save current location to history
    if (foodTruck.location && foodTruck.location.coordinates[0] !== 0 && foodTruck.location.coordinates[1] !== 0) {
      foodTruck.locationHistory.push({
        coordinates: foodTruck.location.coordinates,
        address: foodTruck.location.address,
        city: foodTruck.location.city,
        state: foodTruck.location.state,
        source: foodTruck.location.source,
        confidence: foodTruck.location.confidence,
        notes: foodTruck.location.notes,
        timestamp: foodTruck.location.lastUpdated
      });
    }

    // Update current location
    foodTruck.location = {
      type: 'Point',
      coordinates: [longitude, latitude],
      address: address || '',
      city: city || '',
      state: state || '',
      source: 'owner',
      confidence: 'high',
      notes: notes || 'Owner check-in',
      lastUpdated: new Date()
    };

    // Set as active when checking in
    foodTruck.isActive = true;

    await foodTruck.save();

    // TODO: Add social media posting functionality when autoPostToSocial is true
    let socialMediaMessage = '';
    if (autoPostToSocial && foodTruck.trackingPreferences.autoPostToSocial) {
      socialMediaMessage = 'Auto-posting to social media is enabled but not yet implemented';
    }

    res.json({ 
      message: 'Checked in successfully', 
      foodTruck,
      socialMediaMessage 
    });
  } catch (error) {
    console.error('Check-in error:', error);
    res.status(500).json({ message: 'Error checking in', error: error.message });
  }
};

// Admin location update (for manual social media tracking)
exports.adminUpdateLocation = async (req, res) => {
  try {
    const { latitude, longitude, address, city, state, source, notes, confidence } = req.body;
    const { id: truckId } = req.params;

    // This would normally require admin authentication
    // For now, we'll comment this out and allow it for development
    // if (req.user.role !== 'admin') {
    //   return res.status(403).json({ message: 'Admin access required' });
    // }

    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    const foodTruck = await FoodTruck.findById(truckId);
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Save current location to history
    if (foodTruck.location && foodTruck.location.coordinates[0] !== 0 && foodTruck.location.coordinates[1] !== 0) {
      foodTruck.locationHistory.push({
        coordinates: foodTruck.location.coordinates,
        address: foodTruck.location.address,
        city: foodTruck.location.city,
        state: foodTruck.location.state,
        source: foodTruck.location.source,
        confidence: foodTruck.location.confidence,
        notes: foodTruck.location.notes,
        timestamp: foodTruck.location.lastUpdated
      });
    }

    // Update location from social media or admin source
    foodTruck.location = {
      type: 'Point',
      coordinates: [longitude, latitude],
      address: address || '',
      city: city || '',
      state: state || '',
      source: source || 'admin',
      confidence: confidence || 'medium',
      notes: notes || `Updated via ${source || 'admin'}`,
      lastUpdated: new Date()
    };

    await foodTruck.save();
    res.json({ message: 'Location updated by admin successfully', foodTruck });
  } catch (error) {
    console.error('Admin update location error:', error);
    res.status(500).json({ message: 'Error updating location', error: error.message });
  }
};

// Update business hours
exports.updateHours = async (req, res) => {
  try {
    const { businessHours } = req.body;
    const userId = req.user?.userId || req.user?._id;

    console.log('updateHours called with:', { businessHours, userId });

    if (!userId) {
      return res.status(401).json({ message: 'User not authenticated' });
    }

    const foodTruck = await FoodTruck.findOne({ owner: userId });
    
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    foodTruck.businessHours = businessHours;
    await foodTruck.save({ validateModifiedOnly: true });

    res.json({ message: 'Business hours updated successfully', foodTruck });
  } catch (error) {
    console.error('Update hours error:', error);
    res.status(500).json({ message: 'Error updating business hours', error: error.message });
  }
};

// Update food types
exports.updateFoodTypes = async (req, res) => {
  try {
    const { foodTypes } = req.body;
    const userId = req.user?.userId || req.user?._id;

    const foodTruck = await FoodTruck.findOne({ owner: userId });
    
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    foodTruck.foodTypes = foodTypes;
    await foodTruck.save();

    res.json({ message: 'Food types updated successfully', foodTruck });
  } catch (error) {
    console.error('Update food types error:', error);
    res.status(500).json({ message: 'Error updating food types', error: error.message });
  }
};

// Add rating to food truck
exports.addRating = async (req, res) => {
  try {
    const { rating, review } = req.body;
    const userId = req.user?.userId || req.user?._id;
    const { id: truckId } = req.params;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    const foodTruck = await FoodTruck.findById(truckId);
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Check if user already rated this truck
    const existingRating = foodTruck.ratings.find(r => r.user.toString() === userId.toString());
    if (existingRating) {
      return res.status(400).json({ message: 'You have already rated this food truck' });
    }

    // Add new rating
    foodTruck.ratings.push({
      user: userId,
      rating: rating,
      review: review || '',
      date: new Date()
    });

    // Recalculate average rating
    const totalRatings = foodTruck.ratings.length;
    const sumRatings = foodTruck.ratings.reduce((sum, r) => sum + r.rating, 0);
    foodTruck.averageRating = sumRatings / totalRatings;
    foodTruck.totalReviews = totalRatings;

    await foodTruck.save();
    res.json({ message: 'Rating added successfully', foodTruck });
  } catch (error) {
    console.error('Add rating error:', error);
    res.status(500).json({ message: 'Error adding rating', error: error.message });
  }
};

// Add menu item
exports.addMenuItem = async (req, res) => {
  try {
    const { name, description, price, category } = req.body;
    const userId = req.user?.userId || req.user?._id;

    if (!name || !price || !category) {
      return res.status(400).json({ message: 'Name, price, and category are required' });
    }

    const foodTruck = await FoodTruck.findOne({ owner: userId });
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    foodTruck.menu.push({
      name,
      description: description || '',
      price,
      category,
      available: true
    });

    await foodTruck.save();
    res.json({ message: 'Menu item added successfully', foodTruck });
  } catch (error) {
    console.error('Add menu item error:', error);
    res.status(500).json({ message: 'Error adding menu item', error: error.message });
  }
};

// Delete menu item
exports.deleteMenuItem = async (req, res) => {
  try {
    const { itemId } = req.params;
    const userId = req.user?.userId || req.user?._id;

    const foodTruck = await FoodTruck.findOne({ owner: userId });
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    foodTruck.menu = foodTruck.menu.filter(item => item._id.toString() !== itemId);
    await foodTruck.save();

    res.json({ message: 'Menu item deleted successfully', foodTruck });
  } catch (error) {
    console.error('Delete menu item error:', error);
    res.status(500).json({ message: 'Error deleting menu item', error: error.message });
  }
};

// Get filters for search
exports.getFilters = async (req, res) => {
  try {
    const cuisineTypes = await FoodTruck.distinct('cuisineType');
    const foodTypes = await FoodTruck.distinct('foodTypes');
    
    res.json({
      cuisineTypes: cuisineTypes.filter(type => type),
      foodTypes: foodTypes.filter(type => type)
    });
  } catch (error) {
    console.error('Get filters error:', error);
    res.status(500).json({ message: 'Error fetching filters', error: error.message });
  }
};

// Search food trucks
exports.searchFoodTrucks = async (req, res) => {
  try {
    const { query, lat, lng, radius = 5000, cuisine } = req.query;
    
    let searchQuery = {};
    
    // Text search
    if (query) {
      searchQuery.$or = [
        { name: { $regex: query, $options: 'i' } },
        { businessName: { $regex: query, $options: 'i' } },
        { description: { $regex: query, $options: 'i' } },
        { cuisineType: { $regex: query, $options: 'i' } },
        { foodTypes: { $in: [new RegExp(query, 'i')] } }
      ];
    }
    
    // Location filter
    if (lat && lng) {
      searchQuery.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          $maxDistance: parseInt(radius)
        }
      };
    }

    // Cuisine filter
    if (cuisine) {
      searchQuery.cuisineType = cuisine;
    }

    const foodTrucks = await FoodTruck.find(searchQuery)
      .populate('owner', 'name email businessName')
      .sort('-createdAt');

    res.json(foodTrucks);
  } catch (error) {
    console.error('Search food trucks error:', error);
    res.status(500).json({ message: 'Error searching food trucks', error: error.message });
  }
};

// Get location history for a food truck
exports.getLocationHistory = async (req, res) => {
  try {
    const { id: truckId } = req.params;
    const { limit = 10 } = req.query;

    const foodTruck = await FoodTruck.findById(truckId)
      .populate('locationHistory.reportedBy', 'name')
      .select('locationHistory location');

    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Sort by timestamp and limit results
    const history = foodTruck.locationHistory
      .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
      .slice(0, parseInt(limit));

    res.json({
      currentLocation: foodTruck.location,
      history
    });
  } catch (error) {
    console.error('Get location history error:', error);
    res.status(500).json({ message: 'Error fetching location history', error: error.message });
  }
};

// TODO: GPS Tracking Functions (commented out for future implementation)
/*
// Enable GPS tracking for a food truck
exports.enableGpsTracking = async (req, res) => {
  try {
    const { gpsDeviceId, updateFrequency, businessHoursOnly } = req.body;
    const userId = req.user?.userId || req.user?._id;

    const foodTruck = await FoodTruck.findOne({ owner: userId });
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    foodTruck.location.gpsDeviceId = gpsDeviceId;
    foodTruck.trackingPreferences.enableGpsTracking = true;
    foodTruck.trackingPreferences.gpsUpdateFrequency = updateFrequency || 60;
    foodTruck.trackingPreferences.businessHoursOnly = businessHoursOnly || true;

    await foodTruck.save();
    res.json({ message: 'GPS tracking enabled successfully', foodTruck });
  } catch (error) {
    console.error('Enable GPS tracking error:', error);
    res.status(500).json({ message: 'Error enabling GPS tracking', error: error.message });
  }
};

// GPS location update (called by GPS device or service)
exports.gpsLocationUpdate = async (req, res) => {
  try {
    const { gpsDeviceId, latitude, longitude, accuracy, timestamp } = req.body;

    const foodTruck = await FoodTruck.findOne({ 'location.gpsDeviceId': gpsDeviceId });
    if (!foodTruck) {
      return res.status(404).json({ message: 'Food truck not found for GPS device' });
    }

    // Check if GPS tracking is enabled
    if (!foodTruck.trackingPreferences.enableGpsTracking) {
      return res.status(403).json({ message: 'GPS tracking is disabled for this truck' });
    }

    // Save current location to history
    if (foodTruck.location && foodTruck.location.coordinates[0] !== 0 && foodTruck.location.coordinates[1] !== 0) {
      foodTruck.locationHistory.push({
        coordinates: foodTruck.location.coordinates,
        address: foodTruck.location.address,
        city: foodTruck.location.city,
        state: foodTruck.location.state,
        source: foodTruck.location.source,
        confidence: foodTruck.location.confidence,
        timestamp: foodTruck.location.lastUpdated
      });
    }

    // Update location from GPS
    foodTruck.location = {
      ...foodTruck.location,
      coordinates: [longitude, latitude],
      source: 'gps',
      confidence: accuracy < 10 ? 'high' : accuracy < 50 ? 'medium' : 'low',
      lastUpdated: timestamp ? new Date(timestamp) : new Date(),
      gpsLastUpdate: new Date(),
      gpsAccuracy: accuracy
    };

    await foodTruck.save();
    res.json({ message: 'GPS location updated successfully' });
  } catch (error) {
    console.error('GPS location update error:', error);
    res.status(500).json({ message: 'Error updating GPS location', error: error.message });
  }
};
*/ 
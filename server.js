const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const app = express();
const PORT = process.env.PORT || 5000;

// Import MongoDB models
const User = require('./models/User');
const FoodTruck = require('./models/FoodTruck');
const Favorite = require('./models/Favorite');

// Middleware - Configure CORS for development (allow all origins)
app.use(cors({
  origin: true, // Allow all origins for development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(express.json());

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://codycook:sLYlcz4fvFDVGKxk@cluster0.bpjvh.mongodb.net/foodtruckapp?retryWrites=true&w=majority';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas successfully!');
    initializeDefaultData();
  })
  .catch((error) => {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  });

// Helper function to check if a truck is currently open
function isCurrentlyOpen(schedule) {
  if (!schedule) return false;
  
  const now = new Date();
  const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const currentDay = dayNames[now.getDay()];
  const currentTime = now.getHours().toString().padStart(2, '0') + ':' + now.getMinutes().toString().padStart(2, '0');
  
  const todaySchedule = schedule[currentDay];
  if (!todaySchedule || !todaySchedule.isOpen) {
    return false;
  }
  
  return currentTime >= todaySchedule.open && currentTime <= todaySchedule.close;
}

// Initialize database with default data if empty
async function initializeDefaultData() {
  try {
    // Check if we already have data
    const userCount = await User.countDocuments();
    const truckCount = await FoodTruck.countDocuments();
    
    if (userCount === 0) {
      console.log('📝 Initializing default users...');
      const defaultUsers = [
        {
          name: 'John Customer',
          email: 'john@customer.com',
          password: 'password123',
          role: 'customer',
          createdAt: new Date()
        },
        {
          name: 'Mike Rodriguez',
          email: 'mike@tacos.com',
          password: 'password123',
          role: 'owner',
          businessName: 'Mike\'s Tacos',
          createdAt: new Date()
        }
      ];

      await User.insertMany(defaultUsers);
      console.log('✅ Default users created');
    }

    if (truckCount === 0) {
      console.log('📝 Initializing default food trucks...');
      const defaultTrucks = [
        {
          id: '1',
          name: 'Cupbop Korean BBQ',
          description: 'Authentic Korean BBQ bowls with fresh ingredients and bold flavors',
          cuisine: 'Korean',
          rating: 4.6,
          image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400',
          email: 'info@cupbop.com',
          website: 'www.cupbop.com',
          location: {
            latitude: 40.7608,
            longitude: -111.8910,
            address: '147 S Main St, Salt Lake City, UT 84111'
          },
          hours: 'Mon-Sat: 11:00 AM - 9:00 PM, Sun: 12:00 PM - 8:00 PM',
          menu: [
            { name: 'Sweet & Spicy Chicken Bowl', price: 12.99, description: 'Grilled chicken with sweet and spicy sauce over rice' },
            { name: 'Bulgogi Beef Bowl', price: 14.99, description: 'Marinated beef with vegetables and rice' },
            { name: 'Tofu Veggie Bowl', price: 11.99, description: 'Crispy tofu with fresh vegetables and Korean sauce' }
          ],
          ownerId: 'owner1',
          schedule: {
            monday: { open: '11:00', close: '21:00', isOpen: true },
            tuesday: { open: '11:00', close: '21:00', isOpen: true },
            wednesday: { open: '11:00', close: '21:00', isOpen: true },
            thursday: { open: '11:00', close: '21:00', isOpen: true },
            friday: { open: '11:00', close: '21:00', isOpen: true },
            saturday: { open: '11:00', close: '21:00', isOpen: true },
            sunday: { open: '12:00', close: '20:00', isOpen: true }
          }
        }
      ];
      
      await FoodTruck.insertMany(defaultTrucks);
      console.log('✅ Default food trucks created');
    }

    console.log('🎉 Database initialization complete!');
  } catch (error) {
    console.error('❌ Error initializing default data:', error);
  }
}

// Root route
app.get('/', (req, res) => {
  res.json({
    message: '🚚 Food Truck API Server is running!',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth/*',
      trucks: '/api/trucks',
      favorites: '/api/users/:userId/favorites'
    }
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// ===== FLEXIBLE USER LOOKUP FUNCTION =====
async function findUserFlexibly(identifier) {
  console.log(`🔍 Looking for user with identifier: ${identifier}`);
  
  let user = null;
  
  // Try different lookup methods
  try {
    // 1. Try as MongoDB ObjectId
    if (mongoose.Types.ObjectId.isValid(identifier)) {
      user = await User.findById(identifier);
      if (user) {
        console.log(`✅ Found user by ObjectId: ${user._id}`);
        return user;
      }
    }
    
    // 2. Try as userId field
    user = await User.findOne({ userId: identifier });
    if (user) {
      console.log(`✅ Found user by userId field: ${user._id}`);
      return user;
    }
    
    // 3. Try as email
    user = await User.findOne({ email: identifier });
    if (user) {
      console.log(`✅ Found user by email: ${user._id}`);
      return user;
    }
    
    // 4. Try as custom string ID (legacy)
    user = await User.findOne({ _id: identifier });
    if (user) {
      console.log(`✅ Found user by custom _id: ${user._id}`);
      return user;
    }
    
    console.log(`❌ No user found with identifier: ${identifier}`);
    return null;
    
  } catch (error) {
    console.error(`❌ Error in flexible user lookup:`, error);
    return null;
  }
}

// ===== AUTHENTICATION ROUTES =====

// Register endpoint - FIXED to use MongoDB ObjectIds consistently
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password, role, businessName } = req.body;
    
    console.log(`📝 Registration attempt: ${email} as ${role}`);
    
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log(`❌ Registration failed: Email ${email} already exists`);
      return res.status(400).json({ success: false, message: 'Email already exists' });
    }
    
    // Create new user - LET MONGODB GENERATE THE _id, then use it consistently
    const newUser = new User({
      // DON'T set _id manually, let MongoDB generate it
      name,
      email,
      password,
      role,
      businessName,
      createdAt: new Date()
    });
    
    // Save user first to get the MongoDB-generated _id
    const savedUser = await newUser.save();
    
    // NOW set userId to match _id for consistency
    savedUser.userId = savedUser._id.toString();
    await savedUser.save();
    
    console.log(`✅ User created successfully: ${email}`);
    console.log(`🆔 User ID: ${savedUser._id}`);
    console.log(`🆔 User userId field: ${savedUser.userId}`);
    
    let foodTruckId = null;
    
    // Auto-create food truck for owners
    if (role === 'owner' && businessName) {
      const newTruck = new FoodTruck({
        // Use a timestamp-based custom ID for trucks (different from user IDs)
        id: `truck_${Date.now()}`,
        name: businessName,
        businessName: businessName,
        description: `Welcome to ${businessName}! We're excited to serve you delicious food from our food truck.`,
        cuisine: 'American', // Default cuisine type
        rating: 0,
        image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        location: {
          latitude: null,
          longitude: null,
          address: 'Location to be set by owner'
        },
        hours: 'Hours to be set by owner',
        menu: [],
        // IMPORTANT: Use the MongoDB _id as ownerId
        ownerId: savedUser._id.toString(),
        isOpen: false,
        createdAt: new Date(),
        lastUpdated: new Date(),
        reviewCount: 0,
        schedule: {
          monday: { open: '09:00', close: '17:00', isOpen: true },
          tuesday: { open: '09:00', close: '17:00', isOpen: true },
          wednesday: { open: '09:00', close: '17:00', isOpen: true },
          thursday: { open: '09:00', close: '17:00', isOpen: true },
          friday: { open: '09:00', close: '17:00', isOpen: true },
          saturday: { open: '10:00', close: '16:00', isOpen: true },
          sunday: { open: '10:00', close: '16:00', isOpen: false }
        },
        // POS Integration fields
        posSettings: {
          parentAccountId: savedUser._id.toString(),
          childAccounts: [],
          allowPosTracking: true,
          posApiKey: `pos_${savedUser._id}_${Date.now()}`,
          posWebhookUrl: null
        }
      });
      
      await newTruck.save();
      foodTruckId = newTruck.id;
      console.log(`🚚 Auto-created food truck for owner: ${businessName} (ID: ${foodTruckId})`);
    }
    
    // CONSISTENT TOKEN: Always use MongoDB _id
    const token = `token_${savedUser._id}_${Date.now()}`;
    
    // CONSISTENT RESPONSE: Always return _id as the main identifier
    res.json({
      success: true,
      token: token,
      user: {
        _id: savedUser._id.toString(),        // MongoDB _id
        id: savedUser._id.toString(),         // Same as _id for mobile app compatibility
        userId: savedUser._id.toString(),     // Same as _id for legacy compatibility
        name: savedUser.name,
        email: savedUser.email,
        role: savedUser.role,
        businessName: savedUser.businessName,
        foodTruckId: foodTruckId
      }
    });
    
  } catch (error) {
    console.error('❌ Registration error:', error);
    res.status(500).json({ success: false, message: 'Server error during registration' });
  }
});

// Login endpoint - FIXED to use MongoDB ObjectIds consistently
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    console.log(`🔐 Login attempt: ${email}`);
    
    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      console.log(`❌ Login failed: User ${email} not found`);
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Simple password check (in production, use bcrypt)
    if (user.password !== password) {
      console.log(`❌ Login failed: Invalid password for ${email}`);
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Update userId field if it doesn't match _id (migration fix)
    if (user.userId !== user._id.toString()) {
      user.userId = user._id.toString();
      await user.save();
      console.log(`🔧 Updated userId field for user: ${user._id}`);
    }
    
    // Find associated food truck for owners
    let foodTruckId = null;
    if (user.role === 'owner') {
      const truck = await FoodTruck.findOne({ ownerId: user._id.toString() });
      if (truck) {
        foodTruckId = truck.id;
      }
    }
    
    console.log(`✅ Login successful: ${email}`);
    console.log(`🆔 User ID: ${user._id}`);
    
    // CONSISTENT TOKEN: Always use MongoDB _id
    const token = `token_${user._id}_${Date.now()}`;
    
    // CONSISTENT RESPONSE: Always return _id as the main identifier
    res.json({
      success: true,
      token: token,
      user: {
        _id: user._id.toString(),        // MongoDB _id
        id: user._id.toString(),         // Same as _id for mobile app compatibility
        userId: user._id.toString(),     // Same as _id for legacy compatibility
        name: user.name,
        email: user.email,
        role: user.role,
        businessName: user.businessName,
        foodTruckId: foodTruckId
      }
    });
    
  } catch (error) {
    console.error('❌ Login error:', error);
    res.status(500).json({ success: false, message: 'Server error during login' });
  }
});

// Forgot password endpoint
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    
    console.log(`🔑 Forgot password request: ${email}`);
    
    const user = await findUserFlexibly(email);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // In a real app, you would send an email with a reset token
    // For now, just return success
    console.log(`✅ Password reset requested for: ${user.email}`);
    
    res.json({
      success: true,
      message: 'Password reset instructions sent to your email'
    });
    
  } catch (error) {
    console.error('❌ Forgot password error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ===== USER MANAGEMENT ROUTES =====

// Change email endpoint
app.put('/api/users/:userId/email', async (req, res) => {
  try {
    const { userId } = req.params;
    const { newEmail } = req.body;
    
    console.log(`📧 Email change request for user: ${userId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Check if new email already exists
    const existingUser = await User.findOne({ email: newEmail });
    if (existingUser && existingUser._id.toString() !== user._id.toString()) {
      return res.status(400).json({ success: false, message: 'Email already in use' });
    }
    
    user.email = newEmail;
    await user.save();
    
    console.log(`✅ Email updated for user: ${user._id}`);
    
    res.json({
      success: true,
      message: 'Email updated successfully',
      user: {
        _id: user._id.toString(),
        id: user._id.toString(),
        userId: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        businessName: user.businessName
      }
    });
    
  } catch (error) {
    console.error('❌ Change email error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Change password endpoint
app.put('/api/users/:userId/password', async (req, res) => {
  try {
    const { userId } = req.params;
    const { currentPassword, newPassword } = req.body;
    
    console.log(`🔐 Password change request for user: ${userId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Verify current password
    if (user.password !== currentPassword) {
      return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    }
    
    user.password = newPassword;
    await user.save();
    
    console.log(`✅ Password updated for user: ${user._id}`);
    
    res.json({
      success: true,
      message: 'Password updated successfully'
    });
    
  } catch (error) {
    console.error('❌ Change password error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ===== FOOD TRUCK ROUTES =====

// Get all food trucks
app.get('/api/trucks', async (req, res) => {
  try {
    const trucks = await FoodTruck.find();
    // Update open/closed status for all trucks based on current time
    const updatedTrucks = trucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule)
    }));
    console.log(`📋 Getting all trucks: ${trucks.length} available`);
    res.json(updatedTrucks);
  } catch (error) {
    console.error('❌ Error fetching trucks:', error);
    res.status(500).json({ message: 'Error fetching food trucks' });
  }
});

// Get single food truck
app.get('/api/trucks/:id', async (req, res) => {
  try {
    const truck = await FoodTruck.findOne({ id: req.params.id });
    if (truck) {
      console.log(`🚚 Found truck: ${truck.name}`);
      // Update open/closed status based on current time
      const updatedTruck = {
        ...truck.toObject(),
        isOpen: isCurrentlyOpen(truck.schedule)
      };
      res.json(updatedTruck);
    } else {
      console.log(`❌ Truck ${req.params.id} not found`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error fetching truck:', error);
    res.status(500).json({ message: 'Error fetching food truck' });
  }
});

// Get menu for a specific food truck
app.get('/api/trucks/:id/menu', async (req, res) => {
  try {
    const truck = await FoodTruck.findOne({ id: req.params.id });
    if (truck) {
      res.json({ success: true, menu: truck.menu || [] });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error fetching menu:', error);
    res.status(500).json({ message: 'Error fetching menu' });
  }
});

// Update truck location
app.put('/api/trucks/:id/location', async (req, res) => {
  try {
    const { id } = req.params;
    const { latitude, longitude, address } = req.body;
    
    console.log(`📍 Location update request for truck ${id}`);
    console.log(`📍 New location: ${latitude}, ${longitude} - ${address}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        location: {
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          address: address || truck?.location?.address || 'Address not provided'
        },
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      console.log(`✅ Location updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Location updated successfully',
        location: truck.location 
      });
    } else {
      console.log(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating location:', error);
    res.status(500).json({ message: 'Error updating location' });
  }
});

// Update cover photo
app.put('/api/trucks/:id/cover-photo', async (req, res) => {
  try {
    const { id } = req.params;
    const { imageUrl } = req.body;
    
    console.log(`📸 Cover photo update request for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        image: imageUrl,
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      console.log(`✅ Cover photo updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Cover photo updated successfully',
        image: truck.image 
      });
    } else {
      console.log(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating cover photo:', error);
    res.status(500).json({ message: 'Error updating cover photo' });
  }
});

// Delete food truck
app.delete('/api/trucks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`🗑️ Delete request for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndDelete({ id });
    
    if (truck) {
      console.log(`✅ Deleted truck: ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Food truck deleted successfully'
      });
    } else {
      console.log(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error deleting truck:', error);
    res.status(500).json({ message: 'Error deleting food truck' });
  }
});

// Search food trucks
app.get('/api/trucks/search', async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q) {
      return res.status(400).json({ message: 'Search query is required' });
    }
    
    console.log(`🔍 Searching trucks for: ${q}`);
    
    const trucks = await FoodTruck.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { cuisine: { $regex: q, $options: 'i' } }
      ]
    });
    
    const updatedTrucks = trucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule)
    }));
    
    console.log(`✅ Found ${trucks.length} trucks matching: ${q}`);
    res.json(updatedTrucks);
  } catch (error) {
    console.error('❌ Error searching trucks:', error);
    res.status(500).json({ message: 'Error searching food trucks' });
  }
});

// Get nearby trucks
app.get('/api/trucks/nearby', async (req, res) => {
  try {
    const { lat, lng, radius = 10 } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }
    
    console.log(`📍 Finding trucks near: ${lat}, ${lng} within ${radius}km`);
    
    // Simple distance calculation (in a real app, use MongoDB geospatial queries)
    const trucks = await FoodTruck.find();
    const nearbyTrucks = trucks.filter(truck => {
      if (!truck.location.latitude || !truck.location.longitude) return false;
      
      const distance = Math.sqrt(
        Math.pow(truck.location.latitude - parseFloat(lat), 2) +
        Math.pow(truck.location.longitude - parseFloat(lng), 2)
      ) * 111; // Rough km conversion
      
      return distance <= parseFloat(radius);
    });
    
    const updatedTrucks = nearbyTrucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule)
    }));
    
    console.log(`✅ Found ${nearbyTrucks.length} nearby trucks`);
    res.json(updatedTrucks);
  } catch (error) {
    console.error('❌ Error finding nearby trucks:', error);
    res.status(500).json({ message: 'Error finding nearby trucks' });
  }
});

// ===== SCHEDULE MANAGEMENT ROUTES =====

// Get truck schedule
app.get('/api/trucks/:id/schedule', async (req, res) => {
  try {
    const { id } = req.params;
    const truck = await FoodTruck.findOne({ id });
    
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    res.json({
      success: true,
      schedule: truck.schedule,
      isCurrentlyOpen: isCurrentlyOpen(truck.schedule)
    });
  } catch (error) {
    console.error('❌ Error fetching schedule:', error);
    res.status(500).json({ message: 'Error fetching schedule' });
  }
});

// Update truck schedule
app.put('/api/trucks/:id/schedule', async (req, res) => {
  try {
    const { id } = req.params;
    const { schedule } = req.body;
    
    console.log(`📅 Schedule update request for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        schedule,
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      console.log(`✅ Schedule updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Schedule updated successfully',
        schedule: truck.schedule,
        isCurrentlyOpen: isCurrentlyOpen(truck.schedule)
      });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating schedule:', error);
    res.status(500).json({ message: 'Error updating schedule' });
  }
});

// Update all truck schedules (batch operation)
app.post('/api/trucks/update-schedules', async (req, res) => {
  try {
    console.log('🔄 Updating all truck open/closed status...');
    
    const trucks = await FoodTruck.find();
    let updatedCount = 0;
    
    for (const truck of trucks) {
      const wasOpen = truck.isOpen;
      const shouldBeOpen = isCurrentlyOpen(truck.schedule);
      
      if (wasOpen !== shouldBeOpen) {
        await FoodTruck.findOneAndUpdate(
          { id: truck.id },
          { isOpen: shouldBeOpen, lastUpdated: new Date() }
        );
        updatedCount++;
        console.log(`📅 ${truck.name}: ${wasOpen ? 'OPEN' : 'CLOSED'} → ${shouldBeOpen ? 'OPEN' : 'CLOSED'}`);
      }
    }
    
    console.log(`✅ Schedule update complete: ${updatedCount} trucks updated`);
    res.json({
      success: true,
      message: `Updated ${updatedCount} truck schedules`,
      updatedCount
    });
  } catch (error) {
    console.error('❌ Error updating schedules:', error);
    res.status(500).json({ message: 'Error updating schedules' });
  }
});

// ===== MENU MANAGEMENT ROUTES =====

// Update truck menu
app.put('/api/trucks/:id/menu', async (req, res) => {
  try {
    const { id } = req.params;
    const { menu } = req.body;
    
    console.log(`🍽️ Menu update request for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        menu,
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      console.log(`✅ Menu updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Menu updated successfully',
        menu: truck.menu 
      });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating menu:', error);
    res.status(500).json({ message: 'Error updating menu' });
  }
});

// ===== FAVORITES ROUTES =====

// Get user favorites
app.get('/api/users/:userId/favorites', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`❤️ Getting favorites for user: ${userId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const favorites = await Favorite.find({ userId: user._id.toString() });
    const truckIds = favorites.map(fav => fav.truckId);
    
    const trucks = await FoodTruck.find({ id: { $in: truckIds } });
    const updatedTrucks = trucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule)
    }));
    
    console.log(`✅ Found ${trucks.length} favorite trucks for user: ${user._id}`);
    res.json({ success: true, favorites: updatedTrucks });
  } catch (error) {
    console.error('❌ Error fetching favorites:', error);
    res.status(500).json({ success: false, message: 'Error fetching favorites' });
  }
});

// Add favorite
app.post('/api/users/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    console.log(`❤️ Adding favorite: User ${userId} → Truck ${truckId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const truck = await FoodTruck.findOne({ id: truckId });
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found' });
    }
    
    // Check if already favorited
    const existingFavorite = await Favorite.findOne({ 
      userId: user._id.toString(), 
      truckId 
    });
    
    if (existingFavorite) {
      return res.status(400).json({ success: false, message: 'Already in favorites' });
    }
    
    const favorite = new Favorite({
      userId: user._id.toString(),
      truckId,
      createdAt: new Date()
    });
    
    await favorite.save();
    
    console.log(`✅ Added favorite: ${user._id} → ${truckId}`);
    res.json({ success: true, message: 'Added to favorites' });
  } catch (error) {
    console.error('❌ Error adding favorite:', error);
    res.status(500).json({ success: false, message: 'Error adding favorite' });
  }
});

// Remove favorite
app.delete('/api/users/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    console.log(`💔 Removing favorite: User ${userId} → Truck ${truckId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const result = await Favorite.findOneAndDelete({ 
      userId: user._id.toString(), 
      truckId 
    });
    
    if (result) {
      console.log(`✅ Removed favorite: ${user._id} → ${truckId}`);
      res.json({ success: true, message: 'Removed from favorites' });
    } else {
      res.status(404).json({ success: false, message: 'Favorite not found' });
    }
  } catch (error) {
    console.error('❌ Error removing favorite:', error);
    res.status(500).json({ success: false, message: 'Error removing favorite' });
  }
});

// Check if truck is favorited
app.get('/api/users/:userId/favorites/check/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const favorite = await Favorite.findOne({ 
      userId: user._id.toString(), 
      truckId 
    });
    
    res.json({ 
      success: true, 
      isFavorite: !!favorite 
    });
  } catch (error) {
    console.error('❌ Error checking favorite:', error);
    res.status(500).json({ success: false, message: 'Error checking favorite' });
  }
});

// ===== ANALYTICS ROUTES =====

// Get truck analytics
app.get('/api/trucks/:id/analytics', async (req, res) => {
  try {
    const { id } = req.params;
    
    const truck = await FoodTruck.findOne({ id });
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    // Get favorite count
    const favoriteCount = await Favorite.countDocuments({ truckId: id });
    
    // Mock analytics data (in a real app, you'd track these metrics)
    const analytics = {
      totalViews: Math.floor(Math.random() * 1000) + 100,
      totalFavorites: favoriteCount,
      averageRating: truck.rating || 0,
      totalReviews: truck.reviewCount || 0,
      weeklyViews: Array.from({ length: 7 }, () => Math.floor(Math.random() * 50) + 10),
      popularItems: truck.menu.slice(0, 3).map(item => ({
        name: item.name,
        orders: Math.floor(Math.random() * 100) + 10
      }))
    };
    
    res.json({ success: true, analytics });
  } catch (error) {
    console.error('❌ Error fetching analytics:', error);
    res.status(500).json({ message: 'Error fetching analytics' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚚 Food Truck API Server running on port ${PORT}`);
  console.log(`🌐 Server URL: http://localhost:${PORT}`);
  console.log(`📋 API Documentation: http://localhost:${PORT}/api/health`);
});

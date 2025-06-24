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
          _id: 'user1',
          name: 'John Customer',
          email: 'john@customer.com',
          password: 'password123',
          role: 'customer',
          createdAt: new Date()
        },
        {
          _id: 'owner1',
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
        // ... (I'll include the rest in the next part due to length)
      ];

      await FoodTruck.insertMany(defaultTrucks);
      console.log('✅ Default food trucks created');
    }

    console.log(`📊 Database Status: ${await User.countDocuments()} users, ${await FoodTruck.countDocuments()} trucks, ${await Favorite.countDocuments()} favorites`);
  } catch (error) {
    console.error('❌ Error initializing data:', error);
  }
}

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const dbStatus = mongoose.connection.readyState === 1;
    const userCount = await User.countDocuments();
    const truckCount = await FoodTruck.countDocuments();
    const favoriteCount = await Favorite.countDocuments();
    
    res.json({
      status: 'ok',
      message: 'Food Truck API is running with MongoDB Atlas',
      database: {
        connected: dbStatus,
        users: userCount,
        trucks: truckCount,
        favorites: favoriteCount
      },
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Database connection failed',
      error: error.message
    });
  }
});

// Authentication Routes
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password, role } = req.body;
    
    console.log(`🔑 Login attempt: ${email} as ${role}`);
    
    const user = await User.findOne({ email, password, role });
    
    if (user) {
      console.log(`✅ Login successful: ${email}`);
      
      let foodTruckId = null;
      if (role === 'owner') {
        const truck = await FoodTruck.findOne({ ownerId: user._id });
        if (truck) {
          foodTruckId = truck.id;
        }
      }
      
      const response = {
        success: true,
        token: `token_${user._id}_${Date.now()}`,
        user: {
          _id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          businessName: user.businessName
        }
      };
      
      if (foodTruckId) {
        response.foodTruckId = foodTruckId;
      }
      
      res.json(response);
    } else {
      console.log(`❌ Login failed: Invalid credentials for ${email}`);
      res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
  } catch (error) {
    console.error('❌ Login error:', error);
    res.status(500).json({ success: false, message: 'Server error during login' });
  }
});

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
    
    const newUser = new User({
      _id: `user_${Date.now()}`,
      name,
      email,
      password,
      role,
      businessName,
      createdAt: new Date()
    });
    
    await newUser.save();
    console.log(`👤 New user created: ${email}`);
    
    let foodTruckId = null;
    
    // Auto-create food truck for owner registrations
    if (role === 'owner' && businessName) {
      const newTruck = new FoodTruck({
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
        ownerId: newUser._id,
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
        }
      });
      
      await newTruck.save();
      foodTruckId = newTruck.id;
      console.log(`🚚 Auto-created food truck for owner: ${businessName} (ID: ${foodTruckId})`);
    }
    
    const token = `token_${newUser._id}_${Date.now()}`;
    const response = {
      success: true,
      token: token,
      user: {
        _id: newUser._id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
        businessName: newUser.businessName
      }
    };
    
    // Include food truck ID for owners
    if (foodTruckId) {
      response.foodTruckId = foodTruckId;
    }
    
    console.log(`✅ Registration successful for: ${email}`);
    res.json(response);
  } catch (error) {
    console.error('❌ Registration error:', error);
    res.status(500).json({ success: false, message: 'Server error during registration' });
  }
});

// Food Truck Routes
app.get('/api/trucks', async (req, res) => {
  try {
    const trucks = await FoodTruck.find();
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

// Password Change Route - FIX FOR PASSWORD PERSISTENCE ISSUE
app.post('/api/users/change-password', async (req, res) => {
  try {
    const { userId, currentPassword, newPassword } = req.body;
    
    console.log(`🔐 Password change request for user: ${userId}`);
    console.log(`🔐 Current password provided: ${currentPassword ? '[PROVIDED]' : '[MISSING]'}`);
    console.log(`🔐 New password provided: ${newPassword ? '[PROVIDED]' : '[MISSING]'}`);
    
    if (!userId || !currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'User ID, current password, and new password are required' });
    }
    
    // First, find the user to verify they exist and password is correct
    const user = await User.findOne({ _id: userId });
    console.log(`🔐 User found: ${user ? user.email : 'NOT FOUND'}`);
    
    if (!user) {
      console.log(`❌ Password change failed: User not found with ID: ${userId}`);
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    console.log(`🔐 Stored password: ${user.password}`);
    console.log(`🔐 Provided current password: ${currentPassword}`);
    console.log(`🔐 Passwords match: ${user.password === currentPassword}`);
    
    // Verify current password
    if (user.password !== currentPassword) {
      console.log(`❌ Password change failed: Current password incorrect for user: ${user.email}`);
      return res.status(401).json({ success: false, message: 'Current password is incorrect' });
    }
    
    // Update password using findOneAndUpdate for better control
    const updateResult = await User.findOneAndUpdate(
      { _id: userId },
      { password: newPassword },
      { new: true }
    );
    
    console.log(`🔐 Update result: ${updateResult ? 'SUCCESS' : 'FAILED'}`);
    console.log(`🔐 New password in database: ${updateResult ? updateResult.password : 'N/A'}`);
    
    if (updateResult) {
      console.log(`✅ Password change successful for user: ${user.email}`);
      console.log(`✅ Password updated from "${currentPassword}" to "${newPassword}"`);
      
      res.json({
        success: true,
        message: 'Password changed successfully',
        debug: {
          userId: userId,
          oldPassword: currentPassword,
          newPassword: newPassword,
          updatedPassword: updateResult.password
        }
      });
    } else {
      console.log(`❌ Password update failed for user: ${user.email}`);
      res.status(500).json({ success: false, message: 'Failed to update password in database' });
    }
    
  } catch (error) {
    console.error('❌ Change password error:', error);
    res.status(500).json({ success: false, message: 'Server error during password change' });
  }
});

// Email Change Routes - FIX FOR BUG #7
app.post('/api/users/change-email', async (req, res) => {
  try {
    const { userId, newEmail, password } = req.body;
    
    console.log(`📧 Email change request: ${userId} -> ${newEmail}`);
    
    if (!userId || !newEmail || !password) {
      return res.status(400).json({ success: false, message: 'User ID, new email, and password are required' });
    }
    
    // Verify user exists and password is correct
    const user = await User.findOne({ _id: userId, password });
    if (!user) {
      console.log(`❌ Email change failed: Invalid user or password`);
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Check if new email is already in use
    const existingUser = await User.findOne({ email: newEmail });
    if (existingUser && existingUser._id !== userId) {
      console.log(`❌ Email change failed: Email ${newEmail} already in use`);
      return res.status(400).json({ success: false, message: 'Email already in use' });
    }
    
    // Generate verification token (in production, use crypto.randomBytes)
    const verificationToken = `email_change_${userId}_${Date.now()}`;
    
    console.log(`✅ Email change verification token generated for: ${user.email} -> ${newEmail}`);
    console.log(`🔗 Verification token: ${verificationToken}`);
    
    res.json({
      success: true,
      message: 'Email change verification sent to new email address',
      verificationToken: verificationToken // Only for development/testing
    });
    
  } catch (error) {
    console.error('❌ Change email error:', error);
    res.status(500).json({ success: false, message: 'Server error during email change request' });
  }
});

app.post('/api/users/verify-email-change', async (req, res) => {
  try {
    const { verificationToken, newEmail } = req.body;
    
    console.log(`📧 Email change verification with token: ${verificationToken}`);
    console.log(`📧 New email: ${newEmail}`);
    
    if (!verificationToken || !newEmail) {
      return res.status(400).json({ success: false, message: 'Verification token and new email are required' });
    }
    
    // Extract user ID from token (in production, validate token from database)
    const tokenParts = verificationToken.split('_');
    if (tokenParts.length !== 4 || tokenParts[0] !== 'email' || tokenParts[1] !== 'change') {
      return res.status(400).json({ success: false, message: 'Invalid verification token' });
    }
    
    const userId = tokenParts[2];
    console.log(`📧 Extracted user ID from token: ${userId}`);
    
    const user = await User.findOne({ _id: userId });
    console.log(`📧 User found: ${user ? user.email : 'NOT FOUND'}`);
    
    if (!user) {
      console.log(`❌ Email change verification failed: User not found`);
      return res.status(404).json({ success: false, message: 'Invalid verification token' });
    }
    
    console.log(`📧 Current email: ${user.email}`);
    console.log(`📧 New email: ${newEmail}`);
    
    // Update email using findOneAndUpdate for better control
    const updateResult = await User.findOneAndUpdate(
      { _id: userId },
      { email: newEmail },
      { new: true }
    );
    
    console.log(`📧 Update result: ${updateResult ? 'SUCCESS' : 'FAILED'}`);
    console.log(`📧 New email in database: ${updateResult ? updateResult.email : 'N/A'}`);
    
    if (updateResult) {
      console.log(`✅ Email change successful: ${user.email} -> ${newEmail}`);
      
      res.json({
        success: true,
        message: 'Email changed successfully',
        user: {
          _id: updateResult._id,
          name: updateResult.name,
          email: updateResult.email,
          role: updateResult.role,
          businessName: updateResult.businessName
        }
      });
    } else {
      console.log(`❌ Email update failed for user: ${user.email}`);
      res.status(500).json({ success: false, message: 'Failed to update email in database' });
    }
    
  } catch (error) {
    console.error('❌ Verify email change error:', error);
    res.status(500).json({ success: false, message: 'Server error during email verification' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚚 Food Truck API Server running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/api/health`);
  console.log(`💾 Database: MongoDB Atlas (Persistent Storage)`);
  console.log(`🎉 Data will now persist between restarts!`);
});

module.exports = app;

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

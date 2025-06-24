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
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/foodtruck';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas successfully!');
    initializeDefaultData();
  })
  .catch((error) => {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  });

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
          ownerId: 'owner1'
        },
        {
          id: '2',
          name: 'The Pie Pizzeria',
          description: 'Utah\'s legendary pizza since 1980 - thick crust perfection',
          cuisine: 'Italian',
          rating: 4.4,
          image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
          location: {
            latitude: 40.7505,
            longitude: -111.8652,
            address: '1320 E 200 S, Salt Lake City, UT 84102'
          },
          hours: 'Mon-Thu: 11:00 AM - 10:00 PM, Fri-Sat: 11:00 AM - 11:00 PM, Sun: 12:00 PM - 10:00 PM',
          menu: [
            { name: 'The Pie Supreme', price: 18.99, description: 'Pepperoni, sausage, mushrooms, olives, peppers on thick crust' },
            { name: 'Margherita Pizza', price: 15.99, description: 'Fresh mozzarella, basil, and tomato sauce' },
            { name: 'Garlic Bread', price: 6.99, description: 'Homemade bread with garlic butter and herbs' }
          ],
          ownerId: 'owner1'
        },
        {
          id: '3',
          name: 'Red Iguana Mobile',
          description: 'Award-winning Mexican cuisine with authentic mole sauces',
          cuisine: 'Mexican',
          rating: 4.7,
          image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
          location: {
            latitude: 40.7831,
            longitude: -111.9044,
            address: '736 W North Temple, Salt Lake City, UT 84116'
          },
          hours: 'Mon-Thu: 11:00 AM - 9:00 PM, Fri-Sat: 11:00 AM - 10:00 PM, Sun: 10:00 AM - 9:00 PM',
          menu: [
            { name: 'Mole Enchiladas', price: 16.99, description: 'Three enchiladas with choice of seven mole sauces' },
            { name: 'Carnitas Tacos', price: 13.99, description: 'Slow-cooked pork with onions and cilantro' },
            { name: 'Chile Relleno', price: 15.99, description: 'Roasted poblano pepper stuffed with cheese' }
          ],
          ownerId: 'owner1'
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
    message: 'Food Truck Finder API with MongoDB Atlas',
    version: '2.0.0',
    status: 'running',
    database: 'MongoDB Atlas (Persistent Storage)',
    endpoints: {
      health: '/api/health',
      trucks: '/api/trucks',
      auth: '/api/auth/login',
      register: '/api/auth/register',
      favorites: '/api/users/:userId/favorites'
    }
  });
});

// Health check
app.get('/api/health', async (req, res) => {
  try {
    const userCount = await User.countDocuments();
    const truckCount = await FoodTruck.countDocuments();
    const favoriteCount = await Favorite.countDocuments();
    
    res.json({
      status: 'ok',
      message: 'Food Truck API is running with MongoDB Atlas',
      database: {
        connected: mongoose.connection.readyState === 1,
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
      message: 'Database connection issue',
      error: error.message
    });
  }
});

// Auth Routes (REMOVED PHONE NUMBER REQUIREMENTS)
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password, role } = req.body;
    
    console.log(`🔐 Login attempt: ${email} as ${role}`);
    
    const user = await User.findOne({ email, password, role });
    
    if (user) {
      console.log(`✅ Login successful for: ${email}`);
      const token = `token_${user._id}_${Date.now()}`;
      res.json({
        success: true,
        token: token,
        user: {
          _id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          businessName: user.businessName
        }
      });
    } else {
      console.log(`❌ Login failed for: ${email} as ${role}`);
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
        cuisine: 'American',
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
        reviewCount: 0
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
    console.log(`📋 Getting all trucks: ${trucks.length} available`);
    res.json(trucks);
  } catch (error) {
    console.error('❌ Error fetching trucks:', error);
    res.status(500).json({ message: 'Error fetching food trucks' });
  }
});

app.get('/api/trucks/:id', async (req, res) => {
  try {
    const truck = await FoodTruck.findOne({ id: req.params.id });
    if (truck) {
      console.log(`🚚 Found truck: ${truck.name}`);
      res.json(truck);
    } else {
      console.log(`❌ Truck ${req.params.id} not found`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error fetching truck:', error);
    res.status(500).json({ message: 'Error fetching food truck' });
  }
});

// ===== FAVORITES ROUTES =====
app.get('/api/users/:userId/favorites', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`❤️  Getting favorites for user: ${userId}`);
    
    const favorites = await Favorite.find({ userId });
    const favoriteIds = favorites.map(fav => fav.truckId);
    const favoriteTrucks = await FoodTruck.find({ id: { $in: favoriteIds } });
    
    console.log(`❤️  Found ${favoriteTrucks.length} favorites for user ${userId}`);
    res.json(favoriteTrucks);
  } catch (error) {
    console.error('❌ Error fetching favorites:', error);
    res.status(500).json({ message: 'Error fetching favorites' });
  }
});

app.post('/api/users/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    console.log(`❤️  Adding truck ${truckId} to favorites for user ${userId}`);
    
    const favorite = new Favorite({ userId, truckId });
    await favorite.save();
    
    console.log(`❤️  Favorite added successfully`);
    res.json({ success: true, message: 'Food truck added to favorites' });
  } catch (error) {
    if (error.code === 11000) {
      res.json({ success: true, message: 'Food truck already in favorites' });
    } else {
      console.error('❌ Error adding favorite:', error);
      res.status(500).json({ message: 'Error adding to favorites' });
    }
  }
});

app.delete('/api/users/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    console.log(`💔 Removing truck ${truckId} from favorites for user ${userId}`);
    
    await Favorite.deleteOne({ userId, truckId });
    
    console.log(`💔 Favorite removed successfully`);
    res.json({ success: true, message: 'Food truck removed from favorites' });
  } catch (error) {
    console.error('❌ Error removing favorite:', error);
    res.status(500).json({ message: 'Error removing from favorites' });
  }
});

app.get('/api/users/:userId/favorites/check/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    const favorite = await Favorite.findOne({ userId, truckId });
    const isFavorite = !!favorite;
    console.log(`❤️  Checking if truck ${truckId} is favorite for user ${userId}: ${isFavorite}`);
    res.json({ isFavorite });
  } catch (error) {
    console.error('❌ Error checking favorite:', error);
    res.status(500).json({ message: 'Error checking favorite status' });
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
  console.log(`📞 Phone numbers: REMOVED from all user interactions`);
  console.log(`🎉 Data will now persist between restarts!`);
});

module.exports = app; 
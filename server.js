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
        },
        {
          id: '2',
          name: 'The Pie Pizzeria',
          description: 'Utah\'s legendary pizza since 1980 - thick crust perfection',
          cuisine: 'Italian',
          rating: 4.4,
          image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
          email: 'orders@thepie.com',
          website: 'www.thepie.com',
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
          ownerId: 'owner1',
          schedule: {
            monday: { open: '11:00', close: '22:00', isOpen: true },
            tuesday: { open: '11:00', close: '22:00', isOpen: true },
            wednesday: { open: '11:00', close: '22:00', isOpen: true },
            thursday: { open: '11:00', close: '22:00', isOpen: true },
            friday: { open: '11:00', close: '23:00', isOpen: true },
            saturday: { open: '11:00', close: '23:00', isOpen: true },
            sunday: { open: '12:00', close: '22:00', isOpen: false }
          }
        },
        {
          id: '3',
          name: 'Red Iguana Mobile',
          description: 'Award-winning Mexican cuisine with authentic mole sauces',
          cuisine: 'Mexican',
          rating: 4.7,
          image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
          email: 'mobile@rediguana.com',
          website: 'www.rediguana.com',
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
          ownerId: 'owner1',
          schedule: {
            monday: { open: '11:00', close: '21:00', isOpen: true },
            tuesday: { open: '11:00', close: '21:00', isOpen: true },
            wednesday: { open: '11:00', close: '21:00', isOpen: true },
            thursday: { open: '11:00', close: '21:00', isOpen: true },
            friday: { open: '11:00', close: '22:00', isOpen: true },
            saturday: { open: '11:00', close: '22:00', isOpen: true },
            sunday: { open: '10:00', close: '21:00', isOpen: true }
          }
        },
        {
          id: '4',
          name: 'Crown Burgers Mobile',
          description: 'Utah\'s iconic burger joint with famous pastrami burgers',
          cuisine: 'American',
          rating: 4.3,
          image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
          email: 'contact@crownburgers.com',
          website: 'www.crownburgers.com',
          location: {
            latitude: 40.6892,
            longitude: -111.8315,
            address: '3190 S Highland Dr, Salt Lake City, UT 84106'
          },
          hours: 'Mon-Sat: 10:00 AM - 10:00 PM, Sun: 11:00 AM - 9:00 PM',
          menu: [
            { name: 'Crown Burger', price: 11.99, description: 'Quarter-pound beef patty with pastrami and special sauce' },
            { name: 'Chicken Club', price: 10.99, description: 'Grilled chicken breast with bacon and avocado' },
            { name: 'Onion Rings', price: 5.99, description: 'Beer-battered onion rings with ranch dipping sauce' }
          ],
          ownerId: 'owner1',
          schedule: {
            monday: { open: '10:00', close: '22:00', isOpen: true },
            tuesday: { open: '10:00', close: '22:00', isOpen: true },
            wednesday: { open: '10:00', close: '22:00', isOpen: true },
            thursday: { open: '10:00', close: '22:00', isOpen: true },
            friday: { open: '10:00', close: '22:00', isOpen: true },
            saturday: { open: '10:00', close: '22:00', isOpen: true },
            sunday: { open: '11:00', close: '21:00', isOpen: true }
          }
        },
        {
          id: '5',
          name: 'Sill-Ice Cream Truck',
          description: 'Artisanal ice cream and frozen treats made with local ingredients',
          cuisine: 'Dessert',
          rating: 4.8,
          image: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400',
          email: 'hello@sillicecream.com',
          website: 'www.sillicecream.com',
          location: {
            latitude: 40.7505,
            longitude: -111.8652,
            address: '840 E 900 S, Salt Lake City, UT 84102'
          },
          hours: 'Mon-Sun: 12:00 PM - 8:00 PM (Seasonal)',
          menu: [
            { name: 'Utah Honey Lavender', price: 6.99, description: 'Local honey and lavender ice cream' },
            { name: 'Rocky Road Sundae', price: 8.99, description: 'Chocolate ice cream with marshmallows and nuts' },
            { name: 'Fresh Fruit Popsicle', price: 4.99, description: 'Made with seasonal Utah fruits' }
          ],
          ownerId: 'owner1',
          schedule: {
            monday: { open: '12:00', close: '20:00', isOpen: true },
            tuesday: { open: '12:00', close: '20:00', isOpen: true },
            wednesday: { open: '12:00', close: '20:00', isOpen: true },
            thursday: { open: '12:00', close: '20:00', isOpen: true },
            friday: { open: '12:00', close: '20:00', isOpen: true },
            saturday: { open: '10:00', close: '20:00', isOpen: true },
            sunday: { open: '10:00', close: '20:00', isOpen: true }
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
    message: 'Food Truck Finder API with MongoDB Atlas',
    version: '2.0.0',
    status: 'running',
    database: 'MongoDB Atlas (Persistent Storage)',
    endpoints: {
      health: '/api/health',
      trucks: '/api/trucks',
      auth: '/api/auth/login',
      register: '/api/auth/register',
      favorites: '/api/users/:userId/favorites',
      truckUpdate: '/api/trucks/:id',
      menu: '/api/trucks/:id/menu',
      schedule: '/api/trucks/:id/schedule',
      analytics: '/api/trucks/:id/analytics',
      posSettings: '/api/pos/settings/:ownerId',
      posChildAccounts: '/api/pos/child-accounts/:ownerId'
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
        },
        // POS Integration fields
        posSettings: {
          parentAccountId: newUser._id,
          childAccounts: [],
          allowPosTracking: true,
          posApiKey: `pos_${newUser._id}_${Date.now()}`,
          posWebhookUrl: null
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

// Food Truck Routes with dynamic open/closed status
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

app.put('/api/trucks/:id/location', async (req, res) => {
  try {
    const { latitude, longitude, address } = req.body;
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id: req.params.id },
      {
        location: { latitude, longitude, address },
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      console.log(`📍 Location updated for truck ${req.params.id}: ${latitude}, ${longitude}`);
      res.json({ success: true, message: 'Location updated', truck });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating location:', error);
    res.status(500).json({ message: 'Error updating location' });
  }
});

app.get('/api/trucks/search', async (req, res) => {
  try {
    const query = req.query.q?.toLowerCase() || '';
    const trucks = await FoodTruck.find({
      $or: [
        { name: { $regex: query, $options: 'i' } },
        { description: { $regex: query, $options: 'i' } },
        { cuisine: { $regex: query, $options: 'i' } }
      ]
    });
    console.log(`🔍 Search for "${query}" found ${trucks.length} trucks`);
    res.json(trucks);
  } catch (error) {
    console.error('❌ Error searching trucks:', error);
    res.status(500).json({ message: 'Error searching food trucks' });
  }
});

app.get('/api/trucks/nearby', async (req, res) => {
  try {
    const { lat, lng, radius = 5 } = req.query;
    // For simplicity, return all trucks (in real app, calculate distance)
    const trucks = await FoodTruck.find();
    console.log(`📍 Nearby search: lat=${lat}, lng=${lng}, radius=${radius}km`);
    res.json(trucks);
  } catch (error) {
    console.error('❌ Error fetching nearby trucks:', error);
    res.status(500).json({ message: 'Error fetching nearby trucks' });
  }
});

// Add new food truck (for owners)
app.post('/api/trucks', async (req, res) => {
  try {
    const newTruck = new FoodTruck({
      id: `truck_${Date.now()}`,
      ...req.body,
      createdAt: new Date(),
      lastUpdated: new Date(),
      rating: 0,
      reviewCount: 0
    });
    
    await newTruck.save();
    console.log(`🚚 New truck created: ${newTruck.name}`);
    res.json({ success: true, truck: newTruck });
  } catch (error) {
    console.error('❌ Error creating truck:', error);
    res.status(500).json({ message: 'Error creating food truck' });
  }
});

// Update food truck (for owners)
app.put('/api/trucks/:id', async (req, res) => {
  try {
    const updates = {
      ...req.body,
      lastUpdated: new Date()
    };
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id: req.params.id },
      updates,
      { new: true }
    );
    
    if (truck) {
      console.log(`✅ Updated food truck: ${truck.name} (ID: ${req.params.id})`);
      res.json({ success: true, truck });
    } else {
      console.log(`❌ Truck ${req.params.id} not found for update`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating truck:', error);
    res.status(500).json({ message: 'Error updating food truck' });
  }
});

// Update food truck cover photo
app.put('/api/trucks/:id/cover-photo', async (req, res) => {
  try {
    const { id } = req.params;
    const { imageUrl } = req.body;
    
    console.log(`Updating cover photo for truck ${id} with URL: ${imageUrl}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { image: imageUrl, lastUpdated: new Date() },
      { new: true }
    );
    
    if (truck) {
      console.log(`Successfully updated cover photo for truck ${id}`);
      res.json({ success: true, message: 'Cover photo updated', truck });
    } else {
      console.log(`Truck ${id} not found`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating cover photo:', error);
    res.status(500).json({ message: 'Error updating cover photo' });
  }
});

// Get food truck cover photo
app.get('/api/trucks/:id/cover-photo', async (req, res) => {
  try {
    const { id } = req.params;
    const truck = await FoodTruck.findOne({ id });
    
    if (truck) {
      res.json({ imageUrl: truck.image || null });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error fetching cover photo:', error);
    res.status(500).json({ message: 'Error fetching cover photo' });
  }
});

// ===== MENU MANAGEMENT ROUTES =====
// Update menu items for a food truck
app.put('/api/trucks/:id/menu', async (req, res) => {
  try {
    const { id } = req.params;
    const { menu } = req.body;
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        menu: menu || [],
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      res.json({ success: true, message: 'Menu updated', menu: truck.menu });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating menu:', error);
    res.status(500).json({ message: 'Error updating menu' });
  }
});

// ===== SCHEDULE MANAGEMENT ROUTES =====
// Get schedule for a food truck
app.get('/api/trucks/:id/schedule', async (req, res) => {
  try {
    const { id } = req.params;
    const truck = await FoodTruck.findOne({ id });
    
    if (truck) {
      res.json({ 
        success: true, 
        schedule: truck.schedule || {
          monday: { open: '09:00', close: '17:00', isOpen: true },
          tuesday: { open: '09:00', close: '17:00', isOpen: true },
          wednesday: { open: '09:00', close: '17:00', isOpen: true },
          thursday: { open: '09:00', close: '17:00', isOpen: true },
          friday: { open: '09:00', close: '17:00', isOpen: true },
          saturday: { open: '10:00', close: '16:00', isOpen: true },
          sunday: { open: '10:00', close: '16:00', isOpen: false }
        }
      });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error fetching schedule:', error);
    res.status(500).json({ message: 'Error fetching schedule' });
  }
});

// Update schedule for a food truck
app.put('/api/trucks/:id/schedule', async (req, res) => {
  try {
    const { id } = req.params;
    const { schedule } = req.body;
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        schedule: schedule,
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      res.json({ success: true, message: 'Schedule updated', schedule: truck.schedule });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating schedule:', error);
    res.status(500).json({ message: 'Error updating schedule' });
  }
});

// ===== ANALYTICS ROUTES =====
// Get analytics data for a food truck
app.get('/api/trucks/:id/analytics', async (req, res) => {
  try {
    const { id } = req.params;
    const truck = await FoodTruck.findOne({ id });
    
    if (truck) {
      // Mock analytics data - in production this would come from real data
      const analytics = {
        totalViews: Math.floor(Math.random() * 1000) + 100,
        totalFavorites: await Favorite.countDocuments({ truckId: id }),
        averageRating: truck.rating || 4.2,
        totalReviews: truck.reviewCount || Math.floor(Math.random() * 20) + 5,
        weeklyViews: [
          { day: 'Mon', views: Math.floor(Math.random() * 50) + 10 },
          { day: 'Tue', views: Math.floor(Math.random() * 50) + 10 },
          { day: 'Wed', views: Math.floor(Math.random() * 50) + 10 },
          { day: 'Thu', views: Math.floor(Math.random() * 50) + 10 },
          { day: 'Fri', views: Math.floor(Math.random() * 50) + 10 },
          { day: 'Sat', views: Math.floor(Math.random() * 50) + 10 },
          { day: 'Sun', views: Math.floor(Math.random() * 50) + 10 }
        ],
        monthlyRevenue: [
          { month: 'Jan', revenue: Math.floor(Math.random() * 5000) + 1000 },
          { month: 'Feb', revenue: Math.floor(Math.random() * 5000) + 1000 },
          { month: 'Mar', revenue: Math.floor(Math.random() * 5000) + 1000 },
          { month: 'Apr', revenue: Math.floor(Math.random() * 5000) + 1000 },
          { month: 'May', revenue: Math.floor(Math.random() * 5000) + 1000 },
          { month: 'Jun', revenue: Math.floor(Math.random() * 5000) + 1000 }
        ]
      };
      
      res.json({ success: true, analytics });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error fetching analytics:', error);
    res.status(500).json({ message: 'Error fetching analytics' });
  }
});

// ===== POS INTEGRATION ROUTES =====
// Get POS settings for owner
app.get('/api/pos/settings/:ownerId', async (req, res) => {
  try {
    const { ownerId } = req.params;
    const truck = await FoodTruck.findOne({ ownerId });
    
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    res.json({
      success: true,
      posSettings: truck.posSettings || {
        parentAccountId: ownerId,
        childAccounts: [],
        allowPosTracking: true,
        posApiKey: `pos_${ownerId}_${Date.now()}`,
        posWebhookUrl: null
      }
    });
  } catch (error) {
    console.error('❌ Error fetching POS settings:', error);
    res.status(500).json({ message: 'Error fetching POS settings' });
  }
});

// Create child POS account
app.post('/api/pos/child-account', async (req, res) => {
  try {
    const { parentOwnerId, childAccountName, permissions } = req.body;
    
    const truck = await FoodTruck.findOne({ ownerId: parentOwnerId });
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    const childAccount = {
      id: `child_${Date.now()}`,
      name: childAccountName,
      apiKey: `child_${parentOwnerId}_${Date.now()}`,
      permissions: permissions || ['location_update', 'status_update'],
      createdAt: new Date().toISOString(),
      isActive: true
    };
    
    if (!truck.posSettings) {
      truck.posSettings = {
        parentAccountId: parentOwnerId,
        childAccounts: [],
        allowPosTracking: true,
        posApiKey: `pos_${parentOwnerId}_${Date.now()}`,
        posWebhookUrl: null
      };
    }
    
    truck.posSettings.childAccounts.push(childAccount);
    await truck.save();
    
    console.log(`✅ Created child POS account: ${childAccountName} for ${truck.name}`);
    res.json({ success: true, childAccount });
  } catch (error) {
    console.error('❌ Error creating child account:', error);
    res.status(500).json({ message: 'Error creating child account' });
  }
});

// POS location update (from child account)
app.post('/api/pos/location-update', async (req, res) => {
  try {
    const { apiKey, latitude, longitude, address, isOpen } = req.body;
    
    // Find truck by child API key
    const truck = await FoodTruck.findOne({
      'posSettings.childAccounts.apiKey': apiKey,
      'posSettings.childAccounts.isActive': true
    });
    
    if (!truck) {
      return res.status(401).json({ message: 'Invalid POS API key' });
    }
    
    const childAccount = truck.posSettings.childAccounts.find(child => child.apiKey === apiKey);
    if (!childAccount.permissions.includes('location_update')) {
      return res.status(403).json({ message: 'No permission for location updates' });
    }
    
    // Update truck location
    const updates = {
      location: {
        latitude,
        longitude,
        address: address || truck.location.address
      },
      lastUpdated: new Date()
    };
    
    if (typeof isOpen === 'boolean') {
      updates.isOpen = isOpen;
    }
    
    await FoodTruck.findOneAndUpdate({ id: truck.id }, updates);
    
    console.log(`📍 POS location update for ${truck.name}: ${latitude}, ${longitude}`);
    res.json({ success: true, message: 'Location updated via POS' });
  } catch (error) {
    console.error('❌ Error updating location via POS:', error);
    res.status(500).json({ message: 'Error updating location via POS' });
  }
});

// Get child accounts for owner
app.get('/api/pos/child-accounts/:ownerId', async (req, res) => {
  try {
    const { ownerId } = req.params;
    const truck = await FoodTruck.findOne({ ownerId });
    
    if (!truck || !truck.posSettings) {
      return res.json({ success: true, childAccounts: [] });
    }
    
    res.json({ success: true, childAccounts: truck.posSettings.childAccounts });
  } catch (error) {
    console.error('❌ Error fetching child accounts:', error);
    res.status(500).json({ message: 'Error fetching child accounts' });
  }
});

// Deactivate child account
app.put('/api/pos/child-account/:childId/deactivate', async (req, res) => {
  try {
    const { childId } = req.params;
    const { ownerId } = req.body;
    
    const truck = await FoodTruck.findOne({ ownerId });
    if (!truck || !truck.posSettings) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    const childAccount = truck.posSettings.childAccounts.find(child => child.id === childId);
    if (!childAccount) {
      return res.status(404).json({ message: 'Child account not found' });
    }
    
    childAccount.isActive = false;
    await truck.save();
    
    console.log(`🚫 Deactivated child POS account: ${childAccount.name}`);
    res.json({ success: true, message: 'Child account deactivated' });
  } catch (error) {
    console.error('❌ Error deactivating child account:', error);
    res.status(500).json({ message: 'Error deactivating child account' });
  }
});

// ===== FAVORITES ROUTES =====
// Get user's favorite food trucks
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

// Add food truck to favorites
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
      // Duplicate key error - already favorited
      res.json({ success: true, message: 'Food truck already in favorites' });
    } else {
      console.error('❌ Error adding favorite:', error);
      res.status(500).json({ message: 'Error adding to favorites' });
    }
  }
});

// Remove food truck from favorites
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

// Check if food truck is in favorites
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

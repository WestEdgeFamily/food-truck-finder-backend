const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// File-based database storage
const DATA_DIR = path.join(__dirname, 'data');
const USERS_FILE = path.join(DATA_DIR, 'users.json');
const TRUCKS_FILE = path.join(DATA_DIR, 'trucks.json');
const FAVORITES_FILE = path.join(DATA_DIR, 'favorites.json');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Database functions
function loadData(filePath, defaultData = []) {
  try {
    if (fs.existsSync(filePath)) {
      const data = fs.readFileSync(filePath, 'utf8');
      return JSON.parse(data);
    }
  } catch (error) {
    console.error(`Error loading data from ${filePath}:`, error.message);
  }
  return defaultData;
}

function saveData(filePath, data) {
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    return true;
  } catch (error) {
    console.error(`Error saving data to ${filePath}:`, error.message);
    return false;
  }
}

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

// Initialize database with default data
const defaultUsers = [
  {
    _id: 'user1',
    name: 'John Customer',
    email: 'john@customer.com',
    password: 'password123',
    role: 'customer',
    phone: '(555) 123-4567',
    createdAt: new Date().toISOString()
  },
  {
    _id: 'owner1',
    name: 'Mike Rodriguez',
    email: 'mike@tacos.com',
    password: 'password123',
    role: 'owner',
    phone: '(555) 987-6543',
    businessName: 'Mike\'s Tacos',
    createdAt: new Date().toISOString()
  }
];

// Sample food trucks data with Utah-based businesses + dynamic schedules
const foodTrucks = [
  {
    id: '1',
    _id: '1', // Added for mobile app compatibility
    name: 'Cupbop Korean BBQ',
    businessName: 'Cupbop Korean BBQ',
    description: 'Authentic Korean BBQ bowls with fresh ingredients and bold flavors',
    cuisine: 'Korean',
    cuisineTypes: ['Korean', 'BBQ'], // Added for mobile app compatibility
    rating: 4.6,
    reviewCount: 156,
    image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400',
    location: {
      latitude: 40.7608,
      longitude: -111.8910,
      address: '147 S Main St, Salt Lake City, UT 84111'
    },
    hours: 'Mon-Sat: 11:00 AM - 9:00 PM, Sun: 12:00 PM - 8:00 PM',
    schedule: {
      monday: { open: '11:00', close: '21:00', isOpen: true },
      tuesday: { open: '11:00', close: '21:00', isOpen: true },
      wednesday: { open: '11:00', close: '21:00', isOpen: true },
      thursday: { open: '11:00', close: '21:00', isOpen: true },
      friday: { open: '11:00', close: '21:00', isOpen: true },
      saturday: { open: '11:00', close: '21:00', isOpen: true },
      sunday: { open: '12:00', close: '20:00', isOpen: true }
    },
    phone: '(801) 532-4772',
    email: 'info@cupbop.com',
    menu: [
      { id: '1', name: 'Sweet & Spicy Chicken Bowl', price: 12.99, description: 'Grilled chicken with sweet and spicy sauce over rice' },
      { id: '2', name: 'Bulgogi Beef Bowl', price: 14.99, description: 'Marinated beef with vegetables and rice' },
      { id: '3', name: 'Tofu Veggie Bowl', price: 11.99, description: 'Crispy tofu with fresh vegetables and Korean sauce' }
    ],
    isOpen: true,
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    id: '2',
    _id: '2',
    name: 'The Pie Pizzeria',
    businessName: 'The Pie Pizzeria',
    description: 'Utah\'s legendary pizza since 1980 - thick crust perfection',
    cuisine: 'Italian',
    cuisineTypes: ['Italian', 'Pizza'],
    rating: 4.4,
    reviewCount: 203,
    image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
    location: {
      latitude: 40.7505,
      longitude: -111.8652,
      address: '1320 E 200 S, Salt Lake City, UT 84102'
    },
    hours: 'Mon-Thu: 11:00 AM - 10:00 PM, Fri-Sat: 11:00 AM - 11:00 PM, Sun: 12:00 PM - 10:00 PM',
    schedule: {
      monday: { open: '11:00', close: '22:00', isOpen: true },
      tuesday: { open: '11:00', close: '22:00', isOpen: true },
      wednesday: { open: '11:00', close: '22:00', isOpen: true },
      thursday: { open: '11:00', close: '22:00', isOpen: true },
      friday: { open: '11:00', close: '23:00', isOpen: true },
      saturday: { open: '11:00', close: '23:00', isOpen: true },
      sunday: { open: '12:00', close: '22:00', isOpen: false }
    },
    phone: '(801) 582-0193',
    email: 'info@thepie.com',
    menu: [
      { id: '1', name: 'The Pie Supreme', price: 18.99, description: 'Pepperoni, sausage, mushrooms, olives, peppers on thick crust' },
      { id: '2', name: 'Margherita Pizza', price: 15.99, description: 'Fresh mozzarella, basil, and tomato sauce' },
      { id: '3', name: 'Garlic Bread', price: 6.99, description: 'Homemade bread with garlic butter and herbs' }
    ],
    isOpen: false,
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    id: '3',
    _id: '3',
    name: 'Red Iguana Mobile',
    businessName: 'Red Iguana Mobile',
    description: 'Award-winning Mexican cuisine with authentic mole sauces',
    cuisine: 'Mexican',
    cuisineTypes: ['Mexican', 'Street Food'],
    rating: 4.7,
    reviewCount: 127,
    image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
    location: {
      latitude: 40.7831,
      longitude: -111.9044,
      address: '736 W North Temple, Salt Lake City, UT 84116'
    },
    hours: 'Mon-Thu: 11:00 AM - 9:00 PM, Fri-Sat: 11:00 AM - 10:00 PM, Sun: 10:00 AM - 9:00 PM',
    schedule: {
      monday: { open: '11:00', close: '21:00', isOpen: true },
      tuesday: { open: '11:00', close: '21:00', isOpen: true },
      wednesday: { open: '11:00', close: '21:00', isOpen: true },
      thursday: { open: '11:00', close: '21:00', isOpen: true },
      friday: { open: '11:00', close: '22:00', isOpen: true },
      saturday: { open: '11:00', close: '22:00', isOpen: true },
      sunday: { open: '10:00', close: '21:00', isOpen: true }
    },
    phone: '(801) 322-1489',
    email: 'orders@rediguana.com',
    menu: [
      { id: '1', name: 'Mole Enchiladas', price: 16.99, description: 'Three enchiladas with choice of seven mole sauces' },
      { id: '2', name: 'Carnitas Tacos', price: 13.99, description: 'Slow-cooked pork with onions and cilantro' },
      { id: '3', name: 'Chile Relleno', price: 15.99, description: 'Roasted poblano pepper stuffed with cheese' }
    ],
    isOpen: true,
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    id: '4',
    _id: '4',
    name: 'Crown Burgers Mobile',
    businessName: 'Crown Burgers Mobile',
    description: 'Utah\'s iconic burger joint with famous pastrami burgers',
    cuisine: 'American',
    cuisineTypes: ['American', 'Burgers'],
    rating: 4.3,
    reviewCount: 89,
    image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
    location: {
      latitude: 40.6892,
      longitude: -111.8315,
      address: '3190 S Highland Dr, Salt Lake City, UT 84106'
    },
    hours: 'Mon-Sat: 10:00 AM - 10:00 PM, Sun: 11:00 AM - 9:00 PM',
    schedule: {
      monday: { open: '10:00', close: '22:00', isOpen: true },
      tuesday: { open: '10:00', close: '22:00', isOpen: true },
      wednesday: { open: '10:00', close: '22:00', isOpen: true },
      thursday: { open: '10:00', close: '22:00', isOpen: true },
      friday: { open: '10:00', close: '22:00', isOpen: true },
      saturday: { open: '10:00', close: '22:00', isOpen: true },
      sunday: { open: '11:00', close: '21:00', isOpen: true }
    },
    phone: '(801) 467-6633',
    email: 'info@crownburgers.com',
    menu: [
      { id: '1', name: 'Crown Burger', price: 11.99, description: 'Quarter-pound beef patty with pastrami and special sauce' },
      { id: '2', name: 'Chicken Club', price: 10.99, description: 'Grilled chicken breast with bacon and avocado' },
      { id: '3', name: 'Onion Rings', price: 5.99, description: 'Beer-battered onion rings with ranch dipping sauce' }
    ],
    isOpen: true,
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    id: '5',
    _id: '5',
    name: 'Sill-Ice Cream Truck',
    businessName: 'Sill-Ice Cream Truck',
    description: 'Artisanal ice cream and frozen treats made with local ingredients',
    cuisine: 'Dessert',
    cuisineTypes: ['Desserts', 'Ice Cream'],
    rating: 4.8,
    reviewCount: 92,
    image: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400',
    location: {
      latitude: 40.7505,
      longitude: -111.8652,
      address: '840 E 900 S, Salt Lake City, UT 84102'
    },
    hours: 'Mon-Sun: 12:00 PM - 8:00 PM (Seasonal)',
    schedule: {
      monday: { open: '12:00', close: '20:00', isOpen: true },
      tuesday: { open: '12:00', close: '20:00', isOpen: true },
      wednesday: { open: '12:00', close: '20:00', isOpen: true },
      thursday: { open: '12:00', close: '20:00', isOpen: true },
      friday: { open: '12:00', close: '20:00', isOpen: true },
      saturday: { open: '10:00', close: '20:00', isOpen: true },
      sunday: { open: '10:00', close: '20:00', isOpen: true }
    },
    phone: '(801) 555-SILL',
    email: 'sweet@sill.com',
    menu: [
      { id: '1', name: 'Utah Honey Lavender', price: 6.99, description: 'Local honey and lavender ice cream' },
      { id: '2', name: 'Rocky Road Sundae', price: 8.99, description: 'Chocolate ice cream with marshmallows and nuts' },
      { id: '3', name: 'Fresh Fruit Popsicle', price: 4.99, description: 'Made with seasonal Utah fruits' }
    ],
    isOpen: true,
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  }
];

// Load data from files or initialize with defaults
let users = loadData(USERS_FILE, defaultUsers);
let trucks = loadData(TRUCKS_FILE, foodTrucks);
let userFavorites = loadData(FAVORITES_FILE, {});

// Save initial data if files don't exist
if (!fs.existsSync(USERS_FILE)) {
  saveData(USERS_FILE, users);
}
if (!fs.existsSync(TRUCKS_FILE)) {
  saveData(TRUCKS_FILE, foodTrucks);
}
if (!fs.existsSync(FAVORITES_FILE)) {
  saveData(FAVORITES_FILE, userFavorites);
}

// Helper functions for database operations
function addUser(user) {
  users.push(user);
  return saveData(USERS_FILE, users);
}

function updateTruck(truckId, updates) {
  const index = trucks.findIndex(t => t.id === truckId);
  if (index !== -1) {
    trucks[index] = { ...trucks[index], ...updates };
    return saveData(TRUCKS_FILE, trucks);
  }
  return false;
}

function addTruck(truck) {
  trucks.push(truck);
  return saveData(TRUCKS_FILE, trucks);
}

function updateFavorites(userId, truckId, action) {
  if (!userFavorites[userId]) {
    userFavorites[userId] = [];
  }
  
  if (action === 'add' && !userFavorites[userId].includes(truckId)) {
    userFavorites[userId].push(truckId);
  } else if (action === 'remove') {
    userFavorites[userId] = userFavorites[userId].filter(id => id !== truckId);
  }
  
  return saveData(FAVORITES_FILE, userFavorites);
}

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'Food Truck Finder API',
    version: '1.0.0',
    status: 'running',
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
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Food Truck API is running',
    trucks: trucks.length,
    users: users.length,
    favorites: Object.keys(userFavorites).length,
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Auth Routes
app.post('/api/auth/login', (req, res) => {
  const { email, password, role } = req.body;
  
  const user = users.find(u => u.email === email && u.password === password && u.role === role);
  
  if (user) {
    const token = `token_${user._id}_${Date.now()}`;
    res.json({
      success: true,
      token: token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        businessName: user.businessName
      }
    });
  } else {
    res.status(401).json({ success: false, message: 'Invalid credentials' });
  }
});

app.post('/api/auth/register', (req, res) => {
  const { name, email, password, role, phone, businessName } = req.body;
  
  // Check if user already exists
  if (users.find(u => u.email === email)) {
    return res.status(400).json({ success: false, message: 'Email already exists' });
  }
  
  const newUser = {
    _id: `user_${Date.now()}`,
    name,
    email,
    password,
    role,
    phone,
    businessName,
    createdAt: new Date().toISOString()
  };
  
  addUser(newUser);
  
  let foodTruckId = null;
  
  // Auto-create food truck for owner registrations
  if (role === 'owner' && businessName) {
    const newTruck = {
      id: `truck_${Date.now()}`,
      _id: `truck_${Date.now()}`,
      name: businessName,
      businessName: businessName,
      description: `Welcome to ${businessName}! We're excited to serve you delicious food from our food truck.`,
      cuisine: 'American',
      cuisineTypes: ['American'],
      rating: 0,
      reviewCount: 0,
      image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
      location: {
        latitude: null,
        longitude: null,
        address: 'Location to be set by owner'
      },
      hours: 'Hours to be set by owner',
      schedule: {
        monday: { open: '09:00', close: '17:00', isOpen: true },
        tuesday: { open: '09:00', close: '17:00', isOpen: true },
        wednesday: { open: '09:00', close: '17:00', isOpen: true },
        thursday: { open: '09:00', close: '17:00', isOpen: true },
        friday: { open: '09:00', close: '17:00', isOpen: true },
        saturday: { open: '10:00', close: '16:00', isOpen: true },
        sunday: { open: '10:00', close: '16:00', isOpen: false }
      },
      phone: phone || '',
      email: email || '',
      menu: [],
      ownerId: newUser._id,
      isOpen: false,
      createdAt: new Date().toISOString(),
      lastUpdated: new Date().toISOString(),
      posSettings: {
        parentAccountId: newUser._id,
        childAccounts: [],
        allowPosTracking: true,
        posApiKey: `pos_${newUser._id}_${Date.now()}`,
        posWebhookUrl: null
      }
    };
    
    addTruck(newTruck);
    foodTruckId = newTruck.id;
    console.log(`✅ Auto-created food truck for owner: ${businessName} (ID: ${foodTruckId})`);
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
      phone: newUser.phone,
      businessName: newUser.businessName
    }
  };
  
  if (foodTruckId) {
    response.foodTruckId = foodTruckId;
  }
  
  res.json(response);
});

// Food Truck Routes with dynamic open/closed status
app.get('/api/trucks', (req, res) => {
  // Update open/closed status for all trucks based on current time
  const updatedTrucks = trucks.map(truck => ({
    ...truck,
    isOpen: isCurrentlyOpen(truck.schedule)
  }));
  res.json(updatedTrucks);
});

app.get('/api/trucks/:id', (req, res) => {
  const truck = trucks.find(t => t.id === req.params.id || t._id === req.params.id);
  if (truck) {
    // Update open/closed status based on current time
    const updatedTruck = {
      ...truck,
      isOpen: isCurrentlyOpen(truck.schedule)
    };
    res.json(updatedTruck);
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// Get menu for a specific food truck
app.get('/api/trucks/:id/menu', (req, res) => {
  const truck = trucks.find(t => t.id === req.params.id || t._id === req.params.id);
  if (truck) {
    res.json({ success: true, menu: truck.menu || [] });
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

app.put('/api/trucks/:id/location', (req, res) => {
  const { latitude, longitude, address } = req.body;
  const truckIndex = trucks.findIndex(t => t.id === req.params.id);
  
  if (truckIndex !== -1) {
    updateTruck(req.params.id, {
      location: {
        latitude,
        longitude,
        address
      },
      lastUpdated: new Date().toISOString()
    });
    res.json({ success: true, message: 'Location updated' });
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

app.get('/api/trucks/search', (req, res) => {
  const query = req.query.q?.toLowerCase() || '';
  const filtered = trucks.filter(truck => 
    truck.name.toLowerCase().includes(query) ||
    truck.description.toLowerCase().includes(query) ||
    truck.cuisine.toLowerCase().includes(query)
  );
  res.json(filtered);
});

app.get('/api/trucks/nearby', (req, res) => {
  const { lat, lng, radius = 5 } = req.query;
  // For simplicity, return all trucks (in real app, calculate distance)
  res.json(trucks);
});

// Add new food truck (for owners)
app.post('/api/trucks', (req, res) => {
  const newTruck = {
    id: `truck_${Date.now()}`,
    _id: `truck_${Date.now()}`,
    ...req.body,
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString(),
    rating: 0,
    reviewCount: 0
  };
  
  addTruck(newTruck);
  res.json({ success: true, truck: newTruck });
});

// Update food truck (for owners)
app.put('/api/trucks/:id', (req, res) => {
  const { id } = req.params;
  const updates = {
    ...req.body,
    lastUpdated: new Date().toISOString()
  };
  
  const truckIndex = trucks.findIndex(t => t.id === id);
  
  if (truckIndex !== -1) {
    updateTruck(id, updates);
    const updatedTruck = trucks[truckIndex];
    console.log(`✅ Updated food truck: ${updatedTruck.name} (ID: ${id})`);
    res.json({ success: true, truck: updatedTruck });
  } else {
    console.log(`❌ Truck ${id} not found for update`);
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// Update food truck cover photo
app.put('/api/trucks/:id/cover-photo', (req, res) => {
  const { id } = req.params;
  const { imageUrl } = req.body;
  
  console.log(`Updating cover photo for truck ${id} with URL: ${imageUrl}`);
  
  const truckIndex = trucks.findIndex(t => t.id === id);
  
  if (truckIndex !== -1) {
    updateTruck(id, { image: imageUrl, lastUpdated: new Date().toISOString() });
    console.log(`Successfully updated cover photo for truck ${id}`);
    res.json({ success: true, message: 'Cover photo updated', truck: trucks[truckIndex] });
  } else {
    console.log(`Truck ${id} not found`);
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// Get food truck cover photo
app.get('/api/trucks/:id/cover-photo', (req, res) => {
  const { id } = req.params;
  const truck = trucks.find(t => t.id === id);
  
  if (truck) {
    res.json({ imageUrl: truck.image || null });
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// ===== MENU MANAGEMENT ROUTES =====
// Update menu items for a food truck
app.put('/api/trucks/:id/menu', (req, res) => {
  const { id } = req.params;
  const { menu } = req.body;
  
  const truckIndex = trucks.findIndex(t => t.id === id);
  
  if (truckIndex !== -1) {
    updateTruck(id, { 
      menu: menu || [],
      lastUpdated: new Date().toISOString()
    });
    res.json({ success: true, message: 'Menu updated', menu: trucks[truckIndex].menu });
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// ===== SCHEDULE MANAGEMENT ROUTES =====
// Get schedule for a food truck
app.get('/api/trucks/:id/schedule', (req, res) => {
  const { id } = req.params;
  const truck = trucks.find(t => t.id === id);
  
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
});

// Update schedule for a food truck
app.put('/api/trucks/:id/schedule', (req, res) => {
  const { id } = req.params;
  const { schedule } = req.body;
  
  const truckIndex = trucks.findIndex(t => t.id === id);
  
  if (truckIndex !== -1) {
    updateTruck(id, { 
      schedule: schedule,
      lastUpdated: new Date().toISOString()
    });
    res.json({ success: true, message: 'Schedule updated', schedule: trucks[truckIndex].schedule });
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// ===== ANALYTICS ROUTES =====
// Get analytics data for a food truck
app.get('/api/trucks/:id/analytics', (req, res) => {
  const { id } = req.params;
  const truck = trucks.find(t => t.id === id);
  
  if (truck) {
    // Mock analytics data - in production this would come from real data
    const analytics = {
      totalViews: Math.floor(Math.random() * 1000) + 100,
      totalFavorites: Math.floor(Math.random() * 50) + 10,
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
});

// ===== POS INTEGRATION ROUTES =====
// Get POS settings for owner
app.get('/api/pos/settings/:ownerId', (req, res) => {
  const { ownerId } = req.params;
  const truck = trucks.find(t => t.ownerId === ownerId);
  
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
});

// Create child POS account
app.post('/api/pos/child-account', (req, res) => {
  const { parentOwnerId, childAccountName, permissions } = req.body;
  
  const truck = trucks.find(t => t.ownerId === parentOwnerId);
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
  updateTruck(truck.id, { posSettings: truck.posSettings });
  
  console.log(`✅ Created child POS account: ${childAccountName} for ${truck.name}`);
  res.json({ success: true, childAccount });
});

// POS location update (from child account)
app.post('/api/pos/location-update', (req, res) => {
  const { apiKey, latitude, longitude, address, isOpen } = req.body;
  
  // Find truck by child API key
  const truck = trucks.find(t => 
    t.posSettings?.childAccounts?.some(child => child.apiKey === apiKey && child.isActive)
  );
  
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
    lastUpdated: new Date().toISOString()
  };
  
  if (typeof isOpen === 'boolean') {
    updates.isOpen = isOpen;
  }
  
  updateTruck(truck.id, updates);
  
  console.log(`📍 POS location update for ${truck.name}: ${latitude}, ${longitude}`);
  res.json({ success: true, message: 'Location updated via POS' });
});

// Get child accounts for owner
app.get('/api/pos/child-accounts/:ownerId', (req, res) => {
  const { ownerId } = req.params;
  const truck = trucks.find(t => t.ownerId === ownerId);
  
  if (!truck || !truck.posSettings) {
    return res.json({ success: true, childAccounts: [] });
  }
  
  res.json({ success: true, childAccounts: truck.posSettings.childAccounts });
});

// Deactivate child account
app.put('/api/pos/child-account/:childId/deactivate', (req, res) => {
  const { childId } = req.params;
  const { ownerId } = req.body;
  
  const truck = trucks.find(t => t.ownerId === ownerId);
  if (!truck || !truck.posSettings) {
    return res.status(404).json({ message: 'Food truck not found' });
  }
  
  const childAccount = truck.posSettings.childAccounts.find(child => child.id === childId);
  if (!childAccount) {
    return res.status(404).json({ message: 'Child account not found' });
  }
  
  childAccount.isActive = false;
  updateTruck(truck.id, { posSettings: truck.posSettings });
  
  console.log(`🚫 Deactivated child POS account: ${childAccount.name}`);
  res.json({ success: true, message: 'Child account deactivated' });
});

// ===== FAVORITES ROUTES =====
// Get user's favorite food trucks
app.get('/api/users/:userId/favorites', (req, res) => {
  const { userId } = req.params;
  console.log(`Getting favorites for user: ${userId}`);
  
  const favoriteIds = userFavorites[userId] || [];
  const favoriteTrucks = trucks.filter(truck => favoriteIds.includes(truck.id));
  
  console.log(`Found ${favoriteTrucks.length} favorites for user ${userId}`);
  res.json(favoriteTrucks);
});

// Add food truck to favorites
app.post('/api/users/:userId/favorites/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  console.log(`Adding truck ${truckId} to favorites for user ${userId}`);
  
  updateFavorites(userId, truckId, 'add');
  
  res.json({ success: true, message: 'Food truck added to favorites' });
});

// Remove food truck from favorites
app.delete('/api/users/:userId/favorites/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  console.log(`Removing truck ${truckId} from favorites for user ${userId}`);
  
  updateFavorites(userId, truckId, 'remove');
  
  res.json({ success: true, message: 'Food truck removed from favorites' });
});

// Check if food truck is in favorites
app.get('/api/users/:userId/favorites/check/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  const isFavorite = userFavorites[userId]?.includes(truckId) || false;
  console.log(`Checking if truck ${truckId} is favorite for user ${userId}: ${isFavorite}`);
  res.json({ isFavorite });
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
  console.log(`🍔 Food trucks: ${trucks.length} loaded`);
  console.log(`👥 Users: ${users.length} loaded`);
  console.log(`❤️  Favorites system: Ready`);
  console.log(`⏰ Dynamic open/closed status: Enabled`);
});

module.exports = app;

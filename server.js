const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Data directory and file paths
const DATA_DIR = path.join(__dirname, 'data');
const USERS_FILE = path.join(DATA_DIR, 'users.json');
const TRUCKS_FILE = path.join(DATA_DIR, 'trucks.json');
const FAVORITES_FILE = path.join(DATA_DIR, 'favorites.json');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Helper functions for file operations
function loadData(filePath, defaultData = []) {
  try {
    if (fs.existsSync(filePath)) {
      const data = fs.readFileSync(filePath, 'utf8');
      return JSON.parse(data);
    }
  } catch (error) {
    console.error(`Error loading data from ${filePath}:`, error);
  }
  return defaultData;
}

function saveData(filePath, data) {
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    return true;
  } catch (error) {
    console.error(`Error saving data to ${filePath}:`, error);
    return false;
  }
}

// Default data
const defaultUsers = [
  {
    _id: 'user_1749785616229',
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

const defaultTrucks = [
  {
    _id: '1',
    name: 'Cupbop Korean BBQ',
    businessName: 'Cupbop Korean BBQ',
    description: 'Authentic Korean BBQ bowls with fresh ingredients and bold flavors',
    ownerId: 'owner1',
    cuisineTypes: ['Korean', 'BBQ', 'Asian'],
    image: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7608,
      longitude: -111.8910,
      address: '147 S Main St, Salt Lake City, UT 84111'
    },
    rating: 4.6,
    reviewCount: 342,
    isOpen: true,
    phone: '(801) 532-2877',
    email: 'info@cupbop.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    _id: '2',
    name: 'The Pie Pizzeria',
    businessName: 'The Pie Pizzeria Food Truck',
    description: 'Salt Lake City\'s legendary pizza since 1980, now mobile!',
    ownerId: 'owner2',
    cuisineTypes: ['Italian', 'Pizza'],
    image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7649,
      longitude: -111.8421,
      address: '1320 E 200 S, Salt Lake City, UT 84102'
    },
    rating: 4.4,
    reviewCount: 156,
    isOpen: true,
    phone: '(801) 582-0193',
    email: 'orders@thepie.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    _id: '3',
    name: 'Red Iguana Mobile',
    businessName: 'Red Iguana Food Truck',
    description: 'Award-winning Mexican cuisine featuring authentic mole sauces',
    ownerId: 'owner3',
    cuisineTypes: ['Mexican', 'Street Food'],
    image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7505,
      longitude: -111.9105,
      address: '736 W North Temple, Salt Lake City, UT 84116'
    },
    rating: 4.8,
    reviewCount: 289,
    isOpen: false,
    phone: '(801) 322-1489',
    email: 'catering@rediguana.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    _id: '4',
    name: 'Crown Burgers Mobile',
    businessName: 'Crown Burgers Food Truck',
    description: 'Utah\'s iconic pastrami burger and classic American fare',
    ownerId: 'owner4',
    cuisineTypes: ['American', 'Burgers'],
    image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7282,
      longitude: -111.9011,
      address: '3190 S Highland Dr, Salt Lake City, UT 84106'
    },
    rating: 4.3,
    reviewCount: 198,
    isOpen: true,
    phone: '(801) 467-6633',
    email: 'info@crownburgers.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    _id: '5',
    name: 'Sill-Ice Cream Truck',
    businessName: 'Sill-Ice Artisan Ice Cream',
    description: 'Handcrafted artisan ice cream with unique Utah-inspired flavors',
    ownerId: 'owner5',
    cuisineTypes: ['Desserts', 'Ice Cream', 'Sweets'],
    image: 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7831,
      longitude: -111.9129,
      address: '840 E 900 S, Salt Lake City, UT 84102'
    },
    rating: 4.7,
    reviewCount: 124,
    isOpen: true,
    phone: '(801) 364-2739',
    email: 'hello@sillice.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  }
];

// Load data from files or initialize with defaults
let users = loadData(USERS_FILE, defaultUsers);
let foodTrucks = loadData(TRUCKS_FILE, defaultTrucks);
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
  const index = foodTrucks.findIndex(t => t._id === truckId);
  if (index !== -1) {
    foodTrucks[index] = { ...foodTrucks[index], ...updates };
    return saveData(TRUCKS_FILE, foodTrucks);
  }
  return false;
}

function addTruck(truck) {
  foodTrucks.push(truck);
  return saveData(TRUCKS_FILE, foodTrucks);
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
      favorites: '/api/users/:userId/favorites'
    }
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Food Truck API is running',
    trucks: foodTrucks.length,
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
  const existingUser = users.find(u => u.email === email);
  if (existingUser) {
    return res.status(400).json({ success: false, message: 'User already exists' });
  }
  
  // Create new user
  const newUser = {
    _id: `user_${Date.now()}`,
    name,
    email,
    password,
    role,
    phone,
    businessName: role === 'owner' ? businessName : undefined,
    createdAt: new Date().toISOString()
  };
  
  if (addUser(newUser)) {
    const token = `token_${newUser._id}_${Date.now()}`;
    res.status(201).json({
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
    });
  } else {
    res.status(500).json({ success: false, message: 'Failed to create user' });
  }
});

// Food Truck Routes
app.get('/api/trucks', (req, res) => {
  res.json(foodTrucks);
});

app.get('/api/trucks/:id', (req, res) => {
  const truck = foodTrucks.find(t => t._id === req.params.id);
  if (truck) {
    res.json(truck);
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

app.post('/api/trucks', (req, res) => {
  const newTruck = {
    _id: `truck_${Date.now()}`,
    ...req.body,
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  };
  
  if (addTruck(newTruck)) {
    res.status(201).json(newTruck);
  } else {
    res.status(500).json({ message: 'Failed to create food truck' });
  }
});

app.put('/api/trucks/:id/location', (req, res) => {
  const { latitude, longitude, address } = req.body;
  const updates = {
    location: { latitude, longitude, address },
    lastUpdated: new Date().toISOString()
  };
  
  if (updateTruck(req.params.id, updates)) {
    const updatedTruck = foodTrucks.find(t => t._id === req.params.id);
    res.json(updatedTruck);
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// Search food trucks
app.get('/api/trucks/search', (req, res) => {
  const query = req.query.q?.toLowerCase() || '';
  const filtered = foodTrucks.filter(truck => 
    truck.name.toLowerCase().includes(query) ||
    truck.description.toLowerCase().includes(query) ||
    truck.cuisineTypes.some(cuisine => cuisine.toLowerCase().includes(query))
  );
  res.json(filtered);
});

// Find nearby trucks
app.get('/api/trucks/nearby', (req, res) => {
  const { lat, lng, radius = 10 } = req.query;
  
  if (!lat || !lng) {
    return res.status(400).json({ message: 'Latitude and longitude are required' });
  }
  
  const userLat = parseFloat(lat);
  const userLng = parseFloat(lng);
  const maxRadius = parseFloat(radius);
  
  // Simple distance calculation (not perfectly accurate but good enough for demo)
  const nearby = foodTrucks.filter(truck => {
    const distance = Math.sqrt(
      Math.pow(truck.location.latitude - userLat, 2) + 
      Math.pow(truck.location.longitude - userLng, 2)
    ) * 111; // Rough conversion to km
    
    return distance <= maxRadius;
  });
  
  res.json(nearby);
});

// Favorites Routes
app.get('/api/users/:userId/favorites', (req, res) => {
  const userId = req.params.userId;
  const favoriteIds = userFavorites[userId] || [];
  const favoriteTrucks = foodTrucks.filter(truck => favoriteIds.includes(truck._id));
  res.json(favoriteTrucks);
});

app.post('/api/users/:userId/favorites/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  
  if (updateFavorites(userId, truckId, 'add')) {
    res.json({ success: true, message: 'Added to favorites' });
  } else {
    res.status(500).json({ success: false, message: 'Failed to add to favorites' });
  }
});

app.delete('/api/users/:userId/favorites/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  
  if (updateFavorites(userId, truckId, 'remove')) {
    res.json({ success: true, message: 'Removed from favorites' });
  } else {
    res.status(500).json({ success: false, message: 'Failed to remove from favorites' });
  }
});

app.get('/api/users/:userId/favorites/check/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  const favoriteIds = userFavorites[userId] || [];
  const isFavorite = favoriteIds.includes(truckId);
  res.json({ isFavorite });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚚 Food Truck API Server running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🍔 Food trucks: ${foodTrucks.length} loaded`);
  console.log(`👥 Users: ${users.length} loaded`);
  console.log(`❤️  Favorites system: Ready`);
});

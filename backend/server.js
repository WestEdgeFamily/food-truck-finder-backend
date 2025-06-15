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

const defaultTrucks = [
  {
    _id: '1',
    name: 'Gourmet Tacos',
    businessName: 'Mike\'s Taco Paradise',
    description: 'Authentic Mexican street tacos with premium ingredients',
    ownerId: 'owner1',
    cuisineTypes: ['Mexican', 'Street Food'],
    image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7589,
      longitude: -73.9851,
      address: '123 Broadway, New York, NY'
    },
    rating: 4.5,
    reviewCount: 127,
    isOpen: true,
    phone: '(555) 987-6543',
    email: 'mike@tacos.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    _id: '2',
    name: 'Burger Express',
    businessName: 'Premium Burger Co',
    description: 'Artisanal burgers made with locally sourced beef',
    ownerId: 'owner2',
    cuisineTypes: ['American', 'Burgers'],
    image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7505,
      longitude: -73.9934,
      address: '456 5th Avenue, New York, NY'
    },
    rating: 4.2,
    reviewCount: 89,
    isOpen: true,
    phone: '(555) 555-0123',
    email: 'info@burgerexpress.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    _id: '3',
    name: 'Pizza Mobile',
    businessName: 'Authentic Italian Pizza',
    description: 'Wood-fired Neapolitan pizza made to order',
    ownerId: 'owner3',
    cuisineTypes: ['Italian', 'Pizza'],
    image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7614,
      longitude: -73.9776,
      address: '789 Pizza Street, New York, NY'
    },
    rating: 4.7,
    reviewCount: 203,
    isOpen: false,
    phone: '(555) 444-7890',
    email: 'orders@pizzamobile.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    _id: '4',
    name: 'Korean BBQ Truck',
    businessName: 'Seoul Kitchen on Wheels',
    description: 'Traditional Korean BBQ and fusion dishes',
    ownerId: 'owner4',
    cuisineTypes: ['Korean', 'BBQ', 'Asian'],
    image: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7480,
      longitude: -73.9857,
      address: '321 Korean Way, New York, NY'
    },
    rating: 4.6,
    reviewCount: 156,
    isOpen: true,
    phone: '(555) 777-1234',
    email: 'hello@seoulkitchen.com',
    createdAt: new Date().toISOString(),
    lastUpdated: new Date().toISOString()
  },
  {
    _id: '5',
    name: 'Sweet Dreams Desserts',
    businessName: 'Sweet Dreams Food Truck',
    description: 'Gourmet desserts, ice cream, and sweet treats',
    ownerId: 'owner5',
    cuisineTypes: ['Desserts', 'Ice Cream', 'Sweets'],
    image: 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=800&h=600&fit=crop',
    location: {
      latitude: 40.7530,
      longitude: -73.9900,
      address: '654 Dessert Lane, New York, NY'
    },
    rating: 4.8,
    reviewCount: 92,
    isOpen: true,
    phone: '(555) 888-9999',
    email: 'sweet@dreams.com',
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
  
  const token = `token_${newUser._id}_${Date.now()}`;
  res.json({
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

app.put('/api/trucks/:id/location', (req, res) => {
  const { latitude, longitude, address } = req.body;
  const truckIndex = foodTrucks.findIndex(t => t._id === req.params.id);
  
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
  const filtered = foodTrucks.filter(truck => 
    truck.name.toLowerCase().includes(query) ||
    truck.description.toLowerCase().includes(query) ||
    truck.cuisineTypes.some(cuisine => cuisine.toLowerCase().includes(query))
  );
  res.json(filtered);
});

app.get('/api/trucks/nearby', (req, res) => {
  const { lat, lng, radius = 5 } = req.query;
  // For simplicity, return all trucks (in real app, calculate distance)
  res.json(foodTrucks);
});

// Add new food truck (for owners)
app.post('/api/trucks', (req, res) => {
  const newTruck = {
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

// Update food truck cover photo
app.put('/api/trucks/:id/cover-photo', (req, res) => {
  const { id } = req.params;
  const { imageUrl } = req.body;
  
  console.log(`Updating cover photo for truck ${id} with URL: ${imageUrl}`);
  
  const truckIndex = foodTrucks.findIndex(t => t._id === id);
  
  if (truckIndex !== -1) {
    updateTruck(id, { image: imageUrl, lastUpdated: new Date().toISOString() });
    console.log(`Successfully updated cover photo for truck ${id}`);
    res.json({ success: true, message: 'Cover photo updated', truck: foodTrucks[truckIndex] });
  } else {
    console.log(`Truck ${id} not found`);
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// Get food truck cover photo
app.get('/api/trucks/:id/cover-photo', (req, res) => {
  const { id } = req.params;
  const truck = foodTrucks.find(t => t._id === id);
  
  if (truck) {
    res.json({ imageUrl: truck.image || null });
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

// ===== FAVORITES ROUTES =====
// Get user's favorite food trucks
app.get('/api/users/:userId/favorites', (req, res) => {
  const { userId } = req.params;
  console.log(`Getting favorites for user: ${userId}`);
  
  const favoriteIds = userFavorites[userId] || [];
  const favoriteTrucks = foodTrucks.filter(truck => favoriteIds.includes(truck._id));
  
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
  console.log(`🍔 Food trucks: ${foodTrucks.length} loaded`);
  console.log(`👥 Users: ${users.length} loaded`);
  console.log(`❤️  Favorites system: Ready`);
});

module.exports = app; 

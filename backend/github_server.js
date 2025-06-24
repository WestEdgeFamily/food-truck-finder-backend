const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Mock database
let users = [
  {
    _id: 'user1',
    name: 'John Customer',
    email: 'john@customer.com',
    password: 'password123',
    role: 'customer',
    phone: '(555) 123-4567'
  },
  {
    _id: 'owner1',
    name: 'Mike Rodriguez',
    email: 'mike@tacos.com',
    password: 'password123',
    role: 'owner',
    phone: '(555) 987-6543',
    businessName: 'Mike\'s Tacos'
  }
];

let foodTrucks = [
  {
    _id: '1',
    name: 'Gourmet Tacos',
    businessName: 'Mike\'s Taco Paradise',
    description: 'Authentic Mexican street tacos with premium ingredients',
    ownerId: 'owner1',
    cuisineTypes: ['Mexican', 'Street Food'],
    location: {
      latitude: 40.7589,
      longitude: -73.9851,
      address: '123 Broadway, New York, NY'
    },
    menu: [
      { id: '1', name: 'Carne Asada Taco', price: 4.99, description: 'Grilled beef with onions, cilantro, and salsa' },
      { id: '2', name: 'Al Pastor Taco', price: 4.99, description: 'Marinated pork with pineapple and onions' },
      { id: '3', name: 'Carnitas Burrito', price: 12.99, description: 'Slow-cooked pork with rice, beans, and cheese' },
      { id: '4', name: 'Guacamole & Chips', price: 7.99, description: 'Fresh avocado dip with crispy tortilla chips' }
    ],
    schedule: {
      monday: { open: '10:00', close: '22:00', isOpen: true },
      tuesday: { open: '10:00', close: '22:00', isOpen: true },
      wednesday: { open: '10:00', close: '22:00', isOpen: true },
      thursday: { open: '10:00', close: '22:00', isOpen: true },
      friday: { open: '10:00', close: '23:00', isOpen: true },
      saturday: { open: '10:00', close: '23:00', isOpen: true },
      sunday: { open: '11:00', close: '21:00', isOpen: true }
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
    location: {
      latitude: 40.7505,
      longitude: -73.9934,
      address: '456 5th Avenue, New York, NY'
    },
    menu: [
      { id: '1', name: 'Classic Burger', price: 14.99, description: 'Beef patty with lettuce, tomato, onion, and special sauce' },
      { id: '2', name: 'BBQ Bacon Burger', price: 17.99, description: 'Beef patty with BBQ sauce, bacon, and onion rings' },
      { id: '3', name: 'Veggie Burger', price: 13.99, description: 'Plant-based patty with avocado and sprouts' },
      { id: '4', name: 'Sweet Potato Fries', price: 6.99, description: 'Crispy sweet potato fries with chipotle aioli' }
    ],
    schedule: {
      monday: { open: '11:00', close: '21:00', isOpen: true },
      tuesday: { open: '11:00', close: '21:00', isOpen: true },
      wednesday: { open: '11:00', close: '21:00', isOpen: true },
      thursday: { open: '11:00', close: '21:00', isOpen: true },
      friday: { open: '11:00', close: '22:00', isOpen: true },
      saturday: { open: '11:00', close: '22:00', isOpen: true },
      sunday: { open: '12:00', close: '20:00', isOpen: true }
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
    location: {
      latitude: 40.7614,
      longitude: -73.9776,
      address: '789 Pizza Street, New York, NY'
    },
    menu: [
      { id: '1', name: 'Margherita Pizza', price: 16.99, description: 'Fresh mozzarella, tomato sauce, and basil' },
      { id: '2', name: 'Pepperoni Pizza', price: 19.99, description: 'Classic pepperoni with mozzarella cheese' },
      { id: '3', name: 'Quattro Stagioni', price: 22.99, description: 'Four seasons pizza with ham, mushrooms, artichokes, and olives' },
      { id: '4', name: 'Caesar Salad', price: 12.99, description: 'Romaine lettuce with parmesan and croutons' }
    ],
    schedule: {
      monday: { open: '12:00', close: '21:00', isOpen: true },
      tuesday: { open: '12:00', close: '21:00', isOpen: true },
      wednesday: { open: '12:00', close: '21:00', isOpen: true },
      thursday: { open: '12:00', close: '21:00', isOpen: true },
      friday: { open: '12:00', close: '22:00', isOpen: true },
      saturday: { open: '12:00', close: '22:00', isOpen: true },
      sunday: { open: '12:00', close: '20:00', isOpen: false }
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
    location: {
      latitude: 40.7480,
      longitude: -73.9857,
      address: '321 Korean Way, New York, NY'
    },
    menu: [
      { id: '1', name: 'Bulgogi Bowl', price: 15.99, description: 'Marinated beef with rice and vegetables' },
      { id: '2', name: 'Korean BBQ Tacos', price: 13.99, description: 'Fusion tacos with Korean marinated meat' },
      { id: '3', name: 'Kimchi Fried Rice', price: 12.99, description: 'Spicy fermented cabbage with fried rice' },
      { id: '4', name: 'Korean Corn Dog', price: 8.99, description: 'Crispy hot dog with Korean-style coating' }
    ],
    schedule: {
      monday: { open: '11:00', close: '21:00', isOpen: true },
      tuesday: { open: '11:00', close: '21:00', isOpen: true },
      wednesday: { open: '11:00', close: '21:00', isOpen: true },
      thursday: { open: '11:00', close: '21:00', isOpen: true },
      friday: { open: '11:00', close: '22:00', isOpen: true },
      saturday: { open: '11:00', close: '22:00', isOpen: true },
      sunday: { open: '12:00', close: '20:00', isOpen: true }
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
    location: {
      latitude: 40.7530,
      longitude: -73.9900,
      address: '654 Dessert Lane, New York, NY'
    },
    menu: [
      { id: '1', name: 'Artisan Ice Cream', price: 6.99, description: 'Choose from vanilla, chocolate, or strawberry' },
      { id: '2', name: 'Chocolate Lava Cake', price: 8.99, description: 'Warm chocolate cake with molten center' },
      { id: '3', name: 'Churros with Dulce de Leche', price: 7.99, description: 'Crispy churros with caramel sauce' },
      { id: '4', name: 'Fresh Fruit Parfait', price: 5.99, description: 'Yogurt with seasonal fruits and granola' }
    ],
    schedule: {
      monday: { open: '12:00', close: '21:00', isOpen: true },
      tuesday: { open: '12:00', close: '21:00', isOpen: true },
      wednesday: { open: '12:00', close: '21:00', isOpen: true },
      thursday: { open: '12:00', close: '21:00', isOpen: true },
      friday: { open: '12:00', close: '22:00', isOpen: true },
      saturday: { open: '10:00', close: '22:00', isOpen: true },
      sunday: { open: '10:00', close: '21:00', isOpen: true }
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
  
  users.push(newUser);
  
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
  // Update open/closed status for all trucks based on current time
  const updatedTrucks = foodTrucks.map(truck => ({
    ...truck,
    isOpen: isCurrentlyOpen(truck.schedule)
  }));
  res.json(updatedTrucks);
});

app.get('/api/trucks/:id', (req, res) => {
  const truck = foodTrucks.find(t => t._id === req.params.id);
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
  const truck = foodTrucks.find(t => t._id === req.params.id);
  if (truck) {
    res.json({ success: true, menu: truck.menu || [] });
  } else {
    res.status(404).json({ message: 'Food truck not found' });
  }
});

app.put('/api/trucks/:id/location', (req, res) => {
  const { latitude, longitude, address } = req.body;
  const truckIndex = foodTrucks.findIndex(t => t._id === req.params.id);
  
  if (truckIndex !== -1) {
    foodTrucks[truckIndex].location = {
      latitude,
      longitude,
      address
    };
    foodTrucks[truckIndex].lastUpdated = new Date().toISOString();
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
  
  foodTrucks.push(newTruck);
  res.json({ success: true, truck: newTruck });
});

// Favorites system (in-memory for now)
const userFavorites = {}; // userId -> [truckId, truckId, ...]

// Favorites Routes
app.get('/api/users/:userId/favorites', (req, res) => {
  const { userId } = req.params;
  const favoriteIds = userFavorites[userId] || [];
  const favoriteTrucks = foodTrucks.filter(truck => favoriteIds.includes(truck._id));
  res.json(favoriteTrucks);
});

app.post('/api/users/:userId/favorites/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  
  if (!userFavorites[userId]) {
    userFavorites[userId] = [];
  }
  
  if (!userFavorites[userId].includes(truckId)) {
    userFavorites[userId].push(truckId);
  }
  
  res.json({ success: true, message: 'Food truck added to favorites' });
});

app.delete('/api/users/:userId/favorites/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  
  if (userFavorites[userId]) {
    userFavorites[userId] = userFavorites[userId].filter(id => id !== truckId);
  }
  
  res.json({ success: true, message: 'Food truck removed from favorites' });
});

app.get('/api/users/:userId/favorites/check/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  const isFavorite = userFavorites[userId]?.includes(truckId) || false;
  res.json({ isFavorite });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Food Truck API is running',
    trucks: foodTrucks.length,
    users: users.length,
    favorites: Object.keys(userFavorites).length,
    timestamp: new Date().toISOString()
  });
});

// Helper function to check if a truck is currently open
function isCurrentlyOpen(schedule) {
  const now = new Date();
  const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const currentDay = dayNames[now.getDay()];
  const currentTime = now.getHours().toString().padStart(2, '0') + ':' + now.getMinutes().toString().padStart(2, '0');
  
  const todaySchedule = schedule[currentDay];
  if (!todaySchedule || !todaySchedule.isOpen) {
    return false;
  }
  
  // Convert time strings to minutes for proper comparison
  const timeToMinutes = (timeStr) => {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return hours * 60 + minutes;
  };
  
  const currentMinutes = timeToMinutes(currentTime);
  const openMinutes = timeToMinutes(todaySchedule.open);
  const closeMinutes = timeToMinutes(todaySchedule.close);
  
  return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
}

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚚 Food Truck API Server running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🍔 Food trucks: ${foodTrucks.length} loaded`);
  console.log(`👥 Users: ${users.length} loaded`);
});

module.exports = app; 

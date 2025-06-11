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

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Food Truck API is running',
    trucks: foodTrucks.length,
    users: users.length,
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚚 Food Truck API Server running on port ${PORT}`);
  console.log(`📍 Health check available at /api/health`);
  console.log(`🍔 Food trucks: ${foodTrucks.length} loaded`);
  console.log(`👥 Users: ${users.length} loaded`);
});

module.exports = app;
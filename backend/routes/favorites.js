const express = require('express');
const router = express.Router();

// Favorites system (in-memory for now)
const userFavorites = {}; // userId -> [truckId, truckId, ...]

// Mock food trucks data (should match the main server.js)
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

// GET /api/users/:userId/favorites
router.get('/:userId', (req, res) => {
  const { userId } = req.params;
  const favoriteIds = userFavorites[userId] || [];
  const favoriteTrucks = foodTrucks.filter(truck => favoriteIds.includes(truck._id));
  res.json(favoriteTrucks);
});

// POST /api/users/:userId/favorites/:truckId
router.post('/:userId/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  
  if (!userFavorites[userId]) {
    userFavorites[userId] = [];
  }
  
  if (!userFavorites[userId].includes(truckId)) {
    userFavorites[userId].push(truckId);
  }
  
  res.json({ success: true, message: 'Food truck added to favorites' });
});

// DELETE /api/users/:userId/favorites/:truckId
router.delete('/:userId/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  
  if (userFavorites[userId]) {
    userFavorites[userId] = userFavorites[userId].filter(id => id !== truckId);
  }
  
  res.json({ success: true, message: 'Food truck removed from favorites' });
});

// GET /api/users/:userId/favorites/check/:truckId
router.get('/:userId/check/:truckId', (req, res) => {
  const { userId, truckId } = req.params;
  const isFavorite = userFavorites[userId]?.includes(truckId) || false;
  res.json({ isFavorite });
});

module.exports = router; 
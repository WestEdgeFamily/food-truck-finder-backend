const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

let foodTrucks = [
  {
    _id: '1',
    name: 'Gourmet Tacos',
    description: 'Authentic Mexican street tacos',
    rating: 4.5,
    reviewCount: 127,
    isOpen: true,
    location: { latitude: 40.7589, longitude: -73.9851, address: '123 Broadway, NY' }
  },
  {
    _id: '2', 
    name: 'Burger Express',
    description: 'Artisanal burgers made with locally sourced beef',
    rating: 4.2,
    reviewCount: 89,
    isOpen: true,
    location: { latitude: 40.7505, longitude: -73.9934, address: '456 5th Avenue, NY' }
  }
];

app.get('/api/trucks', (req, res) => {
  res.json(foodTrucks);
});

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Food Truck API is running',
    trucks: foodTrucks.length,
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
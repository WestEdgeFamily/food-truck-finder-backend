const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const socketIo = require('socket.io');
const http = require('http');
const path = require('path');
const connectDB = require('./config/db');
const config = require('./config/config');

// Import routes
const authRoutes = require('./routes/auth');
const foodTruckRoutes = require('./routes/foodTrucks');
const userRoutes = require('./routes/users');
const eventRoutes = require('./routes/events');

// Load environment variables
dotenv.config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: [
      "http://localhost:3000", 
      "http://localhost:3001",
      "https://food-truck-finder.netlify.app"
    ],
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true
  }
});

// Make io accessible to our route handlers
app.set('socketio', io);

// Middleware
app.use(cors({
  origin: [
    "http://localhost:3000", 
    "http://localhost:3001",
    "https://food-truck-finder.netlify.app"
  ],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, '../public')));

// Request logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

// Connect to MongoDB with error handling
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/foodtruckapp', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => {
    console.log('Successfully connected to MongoDB.');
})
.catch((error) => {
    console.error('Error connecting to MongoDB:', error.message);
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/foodtrucks', foodTruckRoutes);
app.use('/api/users', require('./routes/users'));
app.use('/api/users', userRoutes);
app.use('/api/events', eventRoutes);

// WebSocket connection handling
io.on('connection', (socket) => {
  console.log('🔗 Client connected:', socket.id);

  // Join room based on user type
  socket.on('join', (data) => {
    const { userType, userId, truckId } = data;
    
    if (userType === 'customer') {
      socket.join('customers');
      console.log(`👥 Customer ${userId} joined customers room`);
    } else if (userType === 'owner' && truckId) {
      socket.join(`truck_${truckId}`);
      socket.join('truck_owners');
      console.log(`🚚 Truck owner ${userId} joined truck_${truckId} room`);
    }
  });

  // Handle real-time location updates from truck owners
  socket.on('location_update', (data) => {
    console.log('📍 Real-time location update:', data);
    
    // Broadcast to all customers
    socket.to('customers').emit('truck_location_updated', {
      truckId: data.truckId,
      location: data.location,
      timestamp: new Date(),
      source: 'live_gps'
    });
  });

  // Handle truck status changes
  socket.on('status_update', (data) => {
    console.log('🔄 Status update:', data);
    
    // Broadcast to all customers
    io.to('customers').emit('truck_status_updated', {
      truckId: data.truckId,
      isActive: data.isActive,
      timestamp: new Date()
    });
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    console.log('❌ Client disconnected:', socket.id);
  });
});

// Basic route for testing
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/index.html'));
});

// Route for owner dashboard
app.get('/owner-dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/owner-dashboard.html'));
});

// Route for user dashboard
app.get('/user-dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/user-dashboard.html'));
});

// Route for dashboard.html (owner dashboard)
app.get('/dashboard.html', (req, res) => {
    res.sendFile(path.join(__dirname, '../dashboard.html'));
});

app.get('/test', (req, res) => {
    res.json({ message: 'API is working' });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error occurred:', err);
    res.status(500).json({ 
        message: 'Something went wrong!',
        error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
    });
});

// Handle 404 routes
app.use((req, res) => {
    res.status(404).json({ message: 'Route not found' });
});

// Start server
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🌐 WebSocket server ready for real-time updates`);
    console.log(`Access the application at: http://localhost:${PORT}`);
    console.log(`Test the API at: http://localhost:${PORT}/test`);
}); 
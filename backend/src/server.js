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

// Configure CORS origins
const allowedOrigins = [
    "http://localhost:3000",
    "http://localhost:3001",
    "https://food-truck-finder.netlify.app",
    process.env.FRONTEND_URL
].filter(Boolean); // Remove any undefined values

// Socket.IO setup with CORS
const io = socketIo(server, {
    cors: {
        origin: allowedOrigins,
        methods: ["GET", "POST", "PUT", "DELETE"],
        credentials: true,
        allowedHeaders: ["Content-Type", "Authorization"]
    },
    transports: ['websocket', 'polling'],
    allowEIO3: true
});

// Make io accessible to our route handlers
app.set('socketio', io);

// CORS middleware
app.use(cors({
    origin: allowedOrigins,
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files
app.use(express.static(path.join(__dirname, '../public')));

// Connect to MongoDB
connectDB();

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/foodtrucks', foodTruckRoutes);
app.use('/api/users', userRoutes);
app.use('/api/events', eventRoutes);

// Serve dashboard HTML
app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/dashboard.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error occurred:', err);
    res.status(500).json({ 
        message: 'Something went wrong!',
        error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
    });
});

// Start server
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🌐 WebSocket server ready for real-time updates`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`CORS Origins: ${allowedOrigins.join(', ')}`);
}); 
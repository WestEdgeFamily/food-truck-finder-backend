const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const { body, validationResult } = require('express-validator');
require('dotenv').config();

// Import logger and validation
const logger = require('./utils/logger');
const { 
  validateRegister, 
  validateLogin, 
  validateUpdateProfile,
  validateChangeEmail,
  validateChangePassword,
  validateCreateTruck,
  validateUpdateLocation,
  validateMenuItem,
  validateCreateReview,
  validateMongoId,
  validatePagination,
  sanitizeInput
} = require('./middleware/validation');
const { errorHandler, notFound, asyncHandler } = require('./middleware/errorHandler');
const emailService = require('./services/emailService');

// ===== CLOUDINARY IMPORT FOR IMAGE UPLOAD =====
const { upload } = require('./config/cloudinary');

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet());
app.use(compression());

// Logging middleware
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined', { stream: logger.stream }));
}

// Trust proxy headers (required for Render and other platforms behind reverse proxies)
app.set('trust proxy', true);

// JWT Secrets - Required environment variables
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

// Validate required environment variables
if (!JWT_SECRET || !JWT_REFRESH_SECRET) {
  logger.error('❌ Missing required JWT secrets in environment variables');
  process.exit(1);
}

// Rate limiting - configured for platforms behind reverse proxies
const authLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_AUTH_MAX) || 5, // Limit each IP to 5 requests per windowMs
  message: 'Too many authentication attempts, please try again later',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  // Handle reverse proxy headers
  keyGenerator: (req) => {
    // Use X-Forwarded-For if behind proxy, otherwise use req.ip
    return req.headers['x-forwarded-for']?.split(',')[0].trim() || req.ip;
  },
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/api/health';
  }
});

const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_API_MAX) || 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  // Handle reverse proxy headers
  keyGenerator: (req) => {
    // Use X-Forwarded-For if behind proxy, otherwise use req.ip
    return req.headers['x-forwarded-for']?.split(',')[0].trim() || req.ip;
  },
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/api/health';
  }
});

// Apply rate limiting to auth routes
app.use('/api/auth', authLimiter);
app.use('/api', apiLimiter);

// Import MongoDB models
const User = require('./models/User');
const FoodTruck = require('./models/FoodTruck');
const Favorite = require('./models/Favorite');
const Review = require('./models/Review');
const SocialAccount = require('./models/SocialAccount');

// ===== ADD THIS IMPORT NEAR LINE 100 =====
// Import Cloudinary upload configuration
const { upload } = require('./config/cloudinary');

// Body parsing middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// CORS configuration
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) return callback(null, true);
    
    // Allow any localhost port for development
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }
    
    // Allow specific production origins
    const allowedOrigins = [
      'https://food-truck-finder-app.onrender.com',
      'https://foodtruckfinder.app',
      'https://www.foodtruckfinder.app'
    ];
    
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    // Log rejected origin for debugging
    logger.warn(`⚠️ CORS rejected origin: ${origin}`);
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));

// MongoDB connection
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/food-truck-finder';

mongoose.connect(MONGO_URI)
  .then(() => {
    logger.info('✅ Connected to MongoDB');
    initializeDefaultData();
  })
  .catch(err => {
    logger.error('❌ MongoDB connection error:', err);
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

// Password validation helper function
function validatePassword(password) {
  const requirements = {
    minLength: 8,
    hasUppercase: /[A-Z]/.test(password),
    hasLowercase: /[a-z]/.test(password),
    hasNumbers: /\d/.test(password),
    hasSpecialChars: /[!@#$%^&*(),.?":{}|<>]/.test(password)
  };
  
  const isValid = password && 
                  password.length >= requirements.minLength &&
                  requirements.hasUppercase &&
                  requirements.hasLowercase &&
                  requirements.hasNumbers &&
                  requirements.hasSpecialChars;
  
  return {
    isValid,
    requirements: {
      ...requirements,
      length: password ? password.length : 0
    }
  };
}

// Get password requirements (for frontend display)
function getPasswordRequirements() {
  return {
    minLength: 8,
    requireUppercase: true,
    requireLowercase: true,
    requireNumbers: true,
    requireSpecialChars: true,
    description: "Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character (!@#$%^&*(),.?\":{}|<>)"
  };
}

// [Initialize default data function continues from original...]
// [All other existing functions remain the same...]

// JWT Verification Middleware
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ success: false, message: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired' });
    }
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
};

// ===== ALL EXISTING ROUTES REMAIN THE SAME =====
// [Authentication routes, user routes, food truck routes continue as they were...]

// ===== IMAGE UPLOAD ROUTE - ADD THIS AFTER OTHER FOOD TRUCK ROUTES =====
// Upload image for food truck
app.post('/api/trucks/:id/upload-image', verifyToken, upload.single('image'), async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user owns this truck
    const truck = await FoodTruck.findById(id);
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    if (truck.ownerId.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    if (!req.file) {
      return res.status(400).json({ message: 'No image uploaded' });
    }
    
    // Update truck with new image
    truck.image = req.file.path;
    await truck.save();
    
    res.json({
      success: true,
      imageUrl: req.file.path,
      message: 'Image uploaded successfully'
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: 'Upload failed' });
  }
});

// ===== ALL OTHER EXISTING ROUTES CONTINUE AS THEY WERE =====
// [Schedule routes, analytics routes, user management routes, etc...]

// Error handling middleware (should be at the end)
app.use(notFound);
app.use(errorHandler);

// Start server
const server = app.listen(PORT, () => {
  logger.info(`🚀 Food Truck Finder API running on port ${PORT}`);
  logger.info(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`🔒 JWT secrets configured: ${JWT_SECRET ? 'Yes' : 'No'}`);
  logger.info(`📧 Email service configured: ${process.env.EMAIL_USER ? 'Yes' : 'No'}`);
  logger.info(`🔗 API endpoints:`);
  logger.info(`   Auth: http://localhost:${PORT}/api/auth`);
  logger.info(`   Users: http://localhost:${PORT}/api/users`);
  logger.info(`   Food Trucks: http://localhost:${PORT}/api/trucks`);
  logger.info(`   Favorites: http://localhost:${PORT}/api/favorites`);
  logger.info(`   Reviews: http://localhost:${PORT}/api/reviews`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    mongoose.connection.close(false, () => {
      logger.info('MongoDB connection closed');
      process.exit(0);
    });
  });
});

module.exports = app;
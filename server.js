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
const SocialPost = require('./models/SocialPost');
const Campaign = require('./models/Campaign');

// Configure CORS for production
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    // Parse allowed origins from environment variable
    const allowedOrigins = process.env.CORS_ORIGIN 
      ? process.env.CORS_ORIGIN.split(',')
      : ['http://localhost:3000', 'http://localhost:3001']; // Default for development
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Global input sanitization
app.use(sanitizeInput);

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  logger.error('❌ Missing MONGODB_URI in environment variables');
  process.exit(1);
}

mongoose.connect(MONGODB_URI)
  .then(() => {
    logger.info('✅ Connected to MongoDB Atlas successfully!');
    initializeDefaultData();
  })
  .catch((error) => {
    logger.error('❌ MongoDB connection error:', error);
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

// Initialize database with default data if empty
async function initializeDefaultData() {
  try {
    // Check if we already have data
    const userCount = await User.countDocuments();
    const truckCount = await FoodTruck.countDocuments();
    
    if (userCount === 0) {
      logger.info('📝 Initializing default users...');
      const defaultUsers = [
        {
          name: 'John Customer',
          email: 'john@customer.com',
          password: 'TestPass123!',
          role: 'customer',
          createdAt: new Date()
        },
        {
          name: 'Mike Rodriguez',
          email: 'mike@tacos.com',
          password: 'TestPass123!',
          role: 'owner',
          businessName: 'Mike\'s Tacos',
          createdAt: new Date()
        }
      ];

      const createdUsers = await User.insertMany(defaultUsers);
      logger.info('✅ Default users created');
    }
    
    // Find the owner user for truck assignment
    const ownerUser = await User.findOne({ role: 'owner', email: 'mike@tacos.com' });
    
    if (truckCount === 0 && ownerUser) {
      logger.info('📝 Initializing default food trucks...');
      const defaultTrucks = [
        {
          id: '1',
          name: 'Cupbop Korean BBQ',
          description: 'Authentic Korean BBQ bowls with fresh ingredients and bold flavors',
          cuisine: 'Korean',
          rating: 4.6,
          image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400',
          email: 'info@cupbop.com',
          website: 'www.cupbop.com',
          location: {
            latitude: 40.7608,
            longitude: -111.8910,
            address: '147 S Main St, Salt Lake City, UT 84111'
          },
          hours: 'Mon-Sat: 11:00 AM - 9:00 PM, Sun: 12:00 PM - 8:00 PM',
          menu: [
            { name: 'Sweet & Spicy Chicken Bowl', price: 12.99, description: 'Grilled chicken with sweet and spicy sauce over rice' },
            { name: 'Bulgogi Beef Bowl', price: 14.99, description: 'Marinated beef with vegetables and rice' },
            { name: 'Tofu Veggie Bowl', price: 11.99, description: 'Crispy tofu with fresh vegetables and Korean sauce' }
          ],
          ownerId: ownerUser._id.toString(),
          schedule: {
            monday: { open: '00:00', close: '23:59', isOpen: true },
            tuesday: { open: '00:00', close: '23:59', isOpen: true },
            wednesday: { open: '00:00', close: '23:59', isOpen: true },
            thursday: { open: '00:00', close: '23:59', isOpen: true },
            friday: { open: '00:00', close: '23:59', isOpen: true },
            saturday: { open: '00:00', close: '23:59', isOpen: true },
            sunday: { open: '00:00', close: '23:59', isOpen: true }
          }
        },
        {
          id: '2',
          name: 'The Pie Pizzeria',
          description: 'Utah\'s legendary pizza since 1980 - thick crust perfection',
          cuisine: 'Italian',
          rating: 4.4,
          image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
          email: 'orders@thepie.com',
          website: 'www.thepie.com',
          location: {
            latitude: 40.7505,
            longitude: -111.8652,
            address: '1320 E 200 S, Salt Lake City, UT 84102'
          },
          hours: 'Mon-Thu: 11:00 AM - 10:00 PM, Fri-Sat: 11:00 AM - 11:00 PM, Sun: 12:00 PM - 10:00 PM',
          menu: [
            { name: 'The Pie Supreme', price: 18.99, description: 'Pepperoni, sausage, mushrooms, olives, peppers on thick crust' },
            { name: 'Margherita Pizza', price: 15.99, description: 'Fresh mozzarella, basil, and tomato sauce' },
            { name: 'Garlic Bread', price: 6.99, description: 'Homemade bread with garlic butter and herbs' }
          ],
          ownerId: ownerUser._id.toString(),
          schedule: {
            monday: { open: '00:00', close: '23:59', isOpen: true },
            tuesday: { open: '00:00', close: '23:59', isOpen: true },
            wednesday: { open: '00:00', close: '23:59', isOpen: true },
            thursday: { open: '00:00', close: '23:59', isOpen: true },
            friday: { open: '00:00', close: '23:59', isOpen: true },
            saturday: { open: '00:00', close: '23:59', isOpen: true },
            sunday: { open: '00:00', close: '23:59', isOpen: true }
          }
        },
        {
          id: '3',
          name: 'Red Iguana Mobile',
          description: 'Award-winning Mexican cuisine with authentic mole sauces',
          cuisine: 'Mexican',
          rating: 4.7,
          image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
          email: 'mobile@rediguana.com',
          website: 'www.rediguana.com',
          location: {
            latitude: 40.7831,
            longitude: -111.9044,
            address: '736 W North Temple, Salt Lake City, UT 84116'
          },
          hours: 'Mon-Thu: 11:00 AM - 9:00 PM, Fri-Sat: 11:00 AM - 10:00 PM, Sun: 10:00 AM - 9:00 PM',
          menu: [
            { name: 'Mole Enchiladas', price: 16.99, description: 'Three enchiladas with choice of seven mole sauces' },
            { name: 'Carnitas Tacos', price: 13.99, description: 'Slow-cooked pork with onions and cilantro' },
            { name: 'Chile Relleno', price: 15.99, description: 'Roasted poblano pepper stuffed with cheese' }
          ],
          ownerId: ownerUser._id.toString(),
          schedule: {
            monday: { open: '00:00', close: '23:59', isOpen: true },
            tuesday: { open: '00:00', close: '23:59', isOpen: true },
            wednesday: { open: '00:00', close: '23:59', isOpen: true },
            thursday: { open: '00:00', close: '23:59', isOpen: true },
            friday: { open: '00:00', close: '23:59', isOpen: true },
            saturday: { open: '00:00', close: '23:59', isOpen: true },
            sunday: { open: '00:00', close: '23:59', isOpen: true }
          }
        },
        {
          id: '4',
          name: 'Crown Burgers Mobile',
          description: 'Utah\'s iconic burger joint with famous pastrami burgers',
          cuisine: 'American',
          rating: 4.3,
          image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
          email: 'contact@crownburgers.com',
          website: 'www.crownburgers.com',
          location: {
            latitude: 40.6892,
            longitude: -111.8315,
            address: '3190 S Highland Dr, Salt Lake City, UT 84106'
          },
          hours: 'Mon-Sat: 10:00 AM - 10:00 PM, Sun: 11:00 AM - 9:00 PM',
          menu: [
            { name: 'Crown Burger', price: 11.99, description: 'Quarter-pound beef patty with pastrami and special sauce' },
            { name: 'Chicken Club', price: 10.99, description: 'Grilled chicken breast with bacon and avocado' },
            { name: 'Onion Rings', price: 5.99, description: 'Beer-battered onion rings with ranch dipping sauce' }
          ],
          ownerId: ownerUser._id.toString(),
          schedule: {
            monday: { open: '00:00', close: '23:59', isOpen: true },
            tuesday: { open: '00:00', close: '23:59', isOpen: true },
            wednesday: { open: '00:00', close: '23:59', isOpen: true },
            thursday: { open: '00:00', close: '23:59', isOpen: true },
            friday: { open: '00:00', close: '23:59', isOpen: true },
            saturday: { open: '00:00', close: '23:59', isOpen: true },
            sunday: { open: '00:00', close: '23:59', isOpen: true }
          }
        },
        {
          id: '5',
          name: 'Sill-Ice Cream Truck',
          description: 'Artisanal ice cream and frozen treats made with local ingredients',
          cuisine: 'Dessert',
          rating: 4.8,
          image: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400',
          email: 'hello@sillicecream.com',
          website: 'www.sillicecream.com',
          location: {
            latitude: 40.7505,
            longitude: -111.8652,
            address: '840 E 900 S, Salt Lake City, UT 84102'
          },
          hours: 'Mon-Sun: 12:00 PM - 8:00 PM (Seasonal)',
          menu: [
            { name: 'Utah Honey Lavender', price: 6.99, description: 'Local honey and lavender ice cream' },
            { name: 'Rocky Road Sundae', price: 8.99, description: 'Chocolate ice cream with marshmallows and nuts' },
            { name: 'Fresh Fruit Popsicle', price: 4.99, description: 'Made with seasonal Utah fruits' }
          ],
          ownerId: ownerUser._id.toString(),
          schedule: {
            monday: { open: '00:00', close: '23:59', isOpen: true },
            tuesday: { open: '00:00', close: '23:59', isOpen: true },
            wednesday: { open: '00:00', close: '23:59', isOpen: true },
            thursday: { open: '00:00', close: '23:59', isOpen: true },
            friday: { open: '00:00', close: '23:59', isOpen: true },
            saturday: { open: '00:00', close: '23:59', isOpen: true },
            sunday: { open: '00:00', close: '23:59', isOpen: true }
          }
        },
        {
          id: '6',
          name: 'Coffee Roasters Mobile',
          description: 'Specialty coffee and espresso drinks with locally roasted beans',
          cuisine: 'Coffee',
          rating: 4.5,
          image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
          email: 'brew@coffeeroasters.com',
          website: 'www.coffeeroasters.com',
          location: {
            latitude: 40.7589,
            longitude: -111.8883,
            address: '200 S Main St, Salt Lake City, UT 84101'
          },
          hours: 'Mon-Fri: 6:00 AM - 3:00 PM, Sat-Sun: 7:00 AM - 2:00 PM',
          menu: [
            { name: 'Utah Roast Latte', price: 4.99, description: 'Local roasted espresso with steamed milk' },
            { name: 'Cold Brew Float', price: 5.99, description: 'Cold brew coffee with vanilla ice cream' },
            { name: 'Breakfast Burrito', price: 8.99, description: 'Eggs, cheese, and local sausage' }
          ],
          ownerId: ownerUser._id.toString(),
          schedule: {
            monday: { open: '00:00', close: '23:59', isOpen: true },
            tuesday: { open: '00:00', close: '23:59', isOpen: true },
            wednesday: { open: '00:00', close: '23:59', isOpen: true },
            thursday: { open: '00:00', close: '23:59', isOpen: true },
            friday: { open: '00:00', close: '23:59', isOpen: true },
            saturday: { open: '00:00', close: '23:59', isOpen: true },
            sunday: { open: '00:00', close: '23:59', isOpen: true }
          }
        },
        {
          id: '7',
          name: 'Coastal Fish Tacos',
          description: 'Fresh seafood tacos with California-style preparations',
          cuisine: 'Seafood',
          rating: 4.4,
          image: 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400',
          email: 'orders@coastalfishtacos.com',
          website: 'www.coastalfishtacos.com',
          location: {
            latitude: 40.7411,
            longitude: -111.9078,
            address: '600 N 300 W, Salt Lake City, UT 84103'
          },
          hours: 'Tue-Sat: 11:00 AM - 8:00 PM, Sun: 12:00 PM - 6:00 PM',
          menu: [
            { name: 'Baja Fish Tacos', price: 12.99, description: 'Beer-battered fish with cabbage slaw and lime crema' },
            { name: 'Shrimp Ceviche Bowl', price: 14.99, description: 'Fresh shrimp with citrus, avocado, and cilantro' },
            { name: 'Fish & Chips', price: 15.99, description: 'Classic beer-battered cod with hand-cut fries' }
          ],
          ownerId: ownerUser._id.toString(),
          schedule: {
            monday: { open: '00:00', close: '23:59', isOpen: true },
            tuesday: { open: '00:00', close: '23:59', isOpen: true },
            wednesday: { open: '00:00', close: '23:59', isOpen: true },
            thursday: { open: '00:00', close: '23:59', isOpen: true },
            friday: { open: '00:00', close: '23:59', isOpen: true },
            saturday: { open: '00:00', close: '23:59', isOpen: true },
            sunday: { open: '00:00', close: '23:59', isOpen: true }
          }
        },
        {
          id: '8',
          name: 'BBQ Smokehouse Wagon',
          description: 'Authentic BBQ with slow-smoked meats and homemade sauces',
          cuisine: 'BBQ',
          rating: 4.6,
          image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400',
          email: 'pit@bbqsmokehouse.com',
          website: 'www.bbqsmokehouse.com',
          location: {
            latitude: 40.7128,
            longitude: -111.8447,
            address: '1455 S State St, Salt Lake City, UT 84115'
          },
          hours: 'Wed-Sun: 11:00 AM - 9:00 PM',
          menu: [
            { name: 'Brisket Platter', price: 16.99, description: '12-hour smoked brisket with two sides' },
            { name: 'Pulled Pork Sandwich', price: 11.99, description: 'Slow-smoked pork with coleslaw on brioche' },
            { name: 'Ribs Half Rack', price: 18.99, description: 'Baby back ribs with house BBQ sauce' }
          ],
          ownerId: ownerUser._id.toString(),
          schedule: {
            monday: { open: '00:00', close: '23:59', isOpen: true },
            tuesday: { open: '00:00', close: '23:59', isOpen: true },
            wednesday: { open: '00:00', close: '23:59', isOpen: true },
            thursday: { open: '00:00', close: '23:59', isOpen: true },
            friday: { open: '00:00', close: '23:59', isOpen: true },
            saturday: { open: '00:00', close: '23:59', isOpen: true },
            sunday: { open: '00:00', close: '23:59', isOpen: true }
          }
        }
      ];
      
      await FoodTruck.insertMany(defaultTrucks);
      logger.info('✅ Default food trucks created');
    }

    logger.info('🎉 Database initialization complete!');
  } catch (error) {
    logger.error('❌ Error initializing default data:', error);
  }
}

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'Food Truck Finder API with MongoDB Atlas',
    version: '2.0.0',
    status: 'running',
    database: 'MongoDB Atlas (Persistent Storage)',
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
app.get('/api/health', async (req, res) => {
  try {
    const userCount = await User.countDocuments();
    const truckCount = await FoodTruck.countDocuments();
    const favoriteCount = await Favorite.countDocuments();
    
    res.json({
      status: 'ok',
      message: 'Food Truck API is running with MongoDB Atlas',
      database: {
        connected: mongoose.connection.readyState === 1,
        users: userCount,
        trucks: truckCount,
        favorites: favoriteCount
      },
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Database connection issue',
      error: error.message
    });
  }
});

// Password Requirements Route
app.get('/api/auth/password-requirements', (req, res) => {
  res.json({
    success: true,
    requirements: getPasswordRequirements()
  });
});

// Auth Routes (REMOVED PHONE NUMBER REQUIREMENTS)
app.post('/api/auth/login', sanitizeInput, validateLogin, async (req, res) => {
  try {
    const { email, password, role } = req.body;
    
    logger.debug(`🔐 Login attempt: ${email} as ${role}`);
    
    // Find user by email and role only (not password)
    const user = await User.findOne({ email, role });
    
    if (user) {
      // Use bcrypt to compare password
      const isPasswordValid = await user.comparePassword(password);
      
      if (isPasswordValid) {
        // Ensure userId field matches _id for consistency
        if (!user.userId || user.userId !== user._id.toString()) {
          logger.debug(`🔧 Fixing userId field for ${email}`);
          await User.findByIdAndUpdate(user._id, { userId: user._id.toString() });
          user.userId = user._id.toString();
        }
        
        // Update last login
        await User.findByIdAndUpdate(user._id, { lastLogin: new Date() });
        
        logger.info(`✅ Login successful for: ${email}`);
        logger.debug(`🆔 User ID: ${user._id}`);
        
        // Generate JWT token
        const token = jwt.sign(
          { 
            id: user._id.toString(),
            email: user.email,
            role: user.role 
          },
          JWT_SECRET,
          { expiresIn: '24h' }
        );
        
        // Generate refresh token
        const refreshToken = jwt.sign(
          { id: user._id.toString() },
          JWT_REFRESH_SECRET,
          { expiresIn: '7d' }
        );
        
        // Store refresh token in database
        await User.findByIdAndUpdate(user._id, { refreshToken });
        
        // CONSISTENT RESPONSE: Always return _id as the main identifier
        res.json({
          success: true,
          token: token,
          refreshToken: refreshToken,
          user: {
            _id: user._id.toString(),        // MongoDB _id
            id: user._id.toString(),         // Same as _id for mobile app compatibility  
            userId: user._id.toString(),     // Same as _id for legacy compatibility
            name: user.name,
            email: user.email,
            role: user.role,
            businessName: user.businessName
          }
        });
      } else {
        logger.warn(`❌ Login failed: Invalid password for ${email}`);
        res.status(401).json({ success: false, message: 'Invalid credentials' });
      }
    } else {
      logger.warn(`❌ Login failed: User not found ${email} as ${role}`);
      res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
  } catch (error) {
    logger.error('❌ Login error:', error);
    res.status(500).json({ success: false, message: 'Server error during login' });
  }
});

app.post('/api/auth/register', sanitizeInput, validateRegister, async (req, res) => {
  try {
    const { name, email, password, role, businessName } = req.body;
    
    logger.debug(`📝 Registration attempt: ${email} as ${role}`);
    
    // Validate password requirements
    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      logger.warn(`❌ Registration failed: Password does not meet requirements`);
      return res.status(400).json({ 
        success: false, 
        message: 'Password does not meet requirements',
        passwordRequirements: getPasswordRequirements(),
        currentPassword: {
          length: passwordValidation.requirements.length,
          hasUppercase: passwordValidation.requirements.hasUppercase,
          hasLowercase: passwordValidation.requirements.hasLowercase,
          hasNumbers: passwordValidation.requirements.hasNumbers,
          hasSpecialChars: passwordValidation.requirements.hasSpecialChars
        }
      });
    }
    
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      logger.warn(`❌ Registration failed: Email ${email} already exists`);
      return res.status(400).json({ success: false, message: 'Email already exists' });
    }
    
    // Create new user (let MongoDB generate the _id)
    const newUser = new User({
      name,
      email,
      password, // Will be hashed by the User model pre-save hook
      role,
      businessName,
      createdAt: new Date()
    });
    
    // Save user
    const savedUser = await newUser.save();
    
    logger.info(`✅ User created successfully: ${email}`);
    logger.debug(`🆔 User ID: ${savedUser._id}`);
    logger.debug(`🆔 User userId field: ${savedUser.userId}`);
    
    let foodTruckId = null;
    
    // Auto-create food truck for owners
    if (role === 'owner' && businessName) {
      const newTruck = new FoodTruck({
        // Use a timestamp-based custom ID for trucks (different from user IDs)
        id: `truck_${Date.now()}`,
        name: businessName,
        businessName: businessName,
        description: `Welcome to ${businessName}! We're excited to serve you delicious food from our food truck.`,
        cuisine: 'American', // Default cuisine type
        rating: 0,
        image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        location: {
          latitude: null,
          longitude: null,
          address: 'Location to be set by owner'
        },
        hours: 'Hours to be set by owner',
        menu: [],
        // IMPORTANT: Use the MongoDB _id as ownerId
        ownerId: savedUser._id.toString(),
        isOpen: false,
        createdAt: new Date(),
        lastUpdated: new Date(),
        reviewCount: 0,
        schedule: {
          monday: { open: '00:00', close: '23:59', isOpen: true },
          tuesday: { open: '00:00', close: '23:59', isOpen: true },
          wednesday: { open: '00:00', close: '23:59', isOpen: true },
          thursday: { open: '00:00', close: '23:59', isOpen: true },
          friday: { open: '00:00', close: '23:59', isOpen: true },
          saturday: { open: '00:00', close: '23:59', isOpen: true },
          sunday: { open: '00:00', close: '23:59', isOpen: true }
        },
        // POS Integration fields
        posSettings: {
          parentAccountId: savedUser._id.toString(),
          childAccounts: [],
          allowPosTracking: true,
          posApiKey: `pos_${savedUser._id}_${Date.now()}`,
          posWebhookUrl: null
        }
      });
      
      await newTruck.save();
      foodTruckId = newTruck.id;
      logger.info(`🚚 Auto-created food truck for owner: ${businessName} (ID: ${foodTruckId})`);
    }
    
    // Set userId to match _id for consistency
    savedUser.userId = savedUser._id.toString();
    await savedUser.save();
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        id: savedUser._id.toString(),
        email: savedUser.email,
        role: savedUser.role 
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    // Generate refresh token
    const refreshToken = jwt.sign(
      { id: savedUser._id.toString() },
      JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );
    
    // Store refresh token
    savedUser.refreshToken = refreshToken;
    await savedUser.save();
    
    // Send welcome email (don't await to avoid blocking the response)
    emailService.sendWelcomeEmail(savedUser).catch(err => {
      logger.error('Failed to send welcome email:', err);
    });
    
    // CONSISTENT RESPONSE: Always return _id as the main identifier
    res.json({
      success: true,
      token: token,
      refreshToken: refreshToken,
      user: {
        _id: savedUser._id.toString(),        // MongoDB _id
        id: savedUser._id.toString(),         // Same as _id for mobile app compatibility
        userId: savedUser._id.toString(),     // Same as _id for legacy compatibility
        name: savedUser.name,
        email: savedUser.email,
        role: savedUser.role,
        businessName: savedUser.businessName,
        foodTruckId: foodTruckId
      }
    });
    
  } catch (error) {
    logger.error('❌ Registration error:', error);
    res.status(500).json({ success: false, message: 'Server error during registration' });
  }
});

// Get password requirements endpoint
app.get('/api/auth/password-requirements', (req, res) => {
  logger.debug('🔐 Password requirements requested');
  res.json({
    success: true,
    requirements: getPasswordRequirements()
  });
});

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

// Helper function to verify token without middleware
const verifyTokenNoMiddleware = async (authHeader) => {
  try {
    const token = authHeader?.split(' ')[1];
    if (!token) return null;
    
    const decoded = jwt.verify(token, JWT_SECRET);
    return decoded;
  } catch (error) {
    return null;
  }
};

// Token refresh endpoint
app.post('/api/auth/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'Refresh token required' });
    }
    
    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    } catch (error) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }
    
    // Find user and verify refresh token matches
    const user = await User.findById(decoded.id);
    
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }
    
    // Generate new access token
    const newToken = jwt.sign(
      { 
        id: user._id.toString(),
        email: user.email,
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({
      success: true,
      token: newToken
    });
  } catch (error) {
    logger.error('❌ Token refresh error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Logout endpoint
app.post('/api/auth/logout', verifyToken, async (req, res) => {
  try {
    // Clear refresh token
    await User.findByIdAndUpdate(req.user.id, { refreshToken: null });
    
    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    logger.error('❌ Logout error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Food Truck Routes with dynamic open/closed status and pagination
app.get('/api/trucks', async (req, res) => {
  try {
    // Pagination parameters
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    
    // Get total count for pagination metadata
    const totalCount = await FoodTruck.countDocuments({ isActive: true });
    const totalPages = Math.ceil(totalCount / limit);
    
    // Get paginated trucks
    const trucks = await FoodTruck.find({ isActive: true })
      .skip(skip)
      .limit(limit)
      .sort({ lastUpdated: -1 });
    
    // Update open/closed status for all trucks based on current time
    const updatedTrucks = trucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule)
    }));
    
    logger.info(`📋 Getting trucks page ${page}/${totalPages}: ${updatedTrucks.length} trucks`);
    
    // Return paginated response
    res.json({
      success: true,
      data: updatedTrucks,
      pagination: {
        currentPage: page,
        totalPages: totalPages,
        totalItems: totalCount,
        itemsPerPage: limit,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1
      }
    });
  } catch (error) {
    logger.error('❌ Error fetching trucks:', error);
    res.status(500).json({ message: 'Error fetching food trucks' });
  }
});

app.get('/api/trucks/:id', async (req, res) => {
  try {
    const truck = await FoodTruck.findOne({ id: req.params.id });
    if (truck) {
      logger.debug(`🚚 Found truck: ${truck.name}`);
      // Update open/closed status based on current time
      const updatedTruck = {
        ...truck.toObject(),
        isOpen: isCurrentlyOpen(truck.schedule)
      };
      res.json(updatedTruck);
    } else {
      logger.warn(`❌ Truck ${req.params.id} not found`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error fetching truck:', error);
    res.status(500).json({ message: 'Error fetching food truck' });
  }
});

// Get menu for a specific food truck
app.get('/api/trucks/:id/menu', async (req, res) => {
  try {
    const truck = await FoodTruck.findOne({ id: req.params.id });
    if (truck) {
      res.json({ success: true, menu: truck.menu || [] });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error fetching menu:', error);
    res.status(500).json({ message: 'Error fetching menu' });
  }
});

// ===== LOCATION TRACKING ROUTES =====
// Update truck location
app.put('/api/trucks/:id/location', async (req, res) => {
  try {
    const { id } = req.params;
    const { latitude, longitude, address } = req.body;
    
    logger.debug(`📍 Location update request for truck ${id}`);
    logger.debug(`📍 New location: ${latitude}, ${longitude} - ${address}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        location: {
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          address: address || truck?.location?.address || 'Address not provided'
        },
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      logger.info(`✅ Location updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Location updated successfully',
        location: truck.location 
      });
    } else {
      logger.warn(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error updating location:', error);
    res.status(500).json({ message: 'Error updating location' });
  }
});

// ===== COVER PHOTO AND IMAGE ROUTES =====
// Update truck cover photo
app.put('/api/trucks/:id/cover-photo', async (req, res) => {
  try {
    const { id } = req.params;
    const { imageUrl, imageData } = req.body;
    
    logger.debug(`🖼️ Cover photo update request for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        image: imageUrl || imageData || 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      logger.info(`✅ Cover photo updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Cover photo updated successfully',
        image: truck.image 
      });
    } else {
      logger.warn(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error updating cover photo:', error);
    res.status(500).json({ message: 'Error updating cover photo' });
  }
});

// ===== ENHANCED POS ROUTES WITH USER ID HANDLING =====
// Get POS settings for owner - ENHANCED with flexible user lookup
app.get('/api/trucks/:truckId/pos-settings', async (req, res) => {
  try {
    const { truckId } = req.params;
    
    logger.debug(`🔧 POS settings request for truck: ${truckId}`);
    
    // Find truck by ID
    let truck = await FoodTruck.findOne({ id: truckId });
    
    // Also try finding by MongoDB _id if not found by custom id
    if (!truck && truckId.match(/^[0-9a-fA-F]{24}$/)) {
      truck = await FoodTruck.findById(truckId);
    }
    
    if (!truck) {
      logger.warn(`❌ Truck not found: ${truckId}`);
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    const posSettings = truck.posSettings || {
      parentAccountId: truck.ownerId,
      childAccounts: [],
      allowPosTracking: true,
      posApiKey: `pos_${truck.ownerId}_${Date.now()}`,
      posWebhookUrl: null
    };
    
    logger.info(`✅ POS settings found for ${truck.name}`);
    res.json({
      success: true,
      posSettings: posSettings
    });
  } catch (error) {
    logger.error('❌ Error fetching POS settings:', error);
    res.status(500).json({ message: 'Error fetching POS settings' });
  }
});

// ===== SCHEDULE MANAGEMENT ROUTES =====
// Get schedule for a food truck
app.get('/api/trucks/:id/schedule', async (req, res) => {
  try {
    const { id } = req.params;
    const truck = await FoodTruck.findOne({ id });
    
    if (truck) {
      res.json({ 
        success: true, 
        schedule: truck.schedule || {
          monday: { open: '00:00', close: '23:59', isOpen: true },
          tuesday: { open: '00:00', close: '23:59', isOpen: true },
          wednesday: { open: '00:00', close: '23:59', isOpen: true },
          thursday: { open: '00:00', close: '23:59', isOpen: true },
          friday: { open: '00:00', close: '23:59', isOpen: true },
          saturday: { open: '00:00', close: '23:59', isOpen: true },
          sunday: { open: '00:00', close: '23:59', isOpen: true }
        }
      });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error fetching schedule:', error);
    res.status(500).json({ message: 'Error fetching schedule' });
  }
});

// Update schedule for a food truck
app.put('/api/trucks/:id/schedule', async (req, res) => {
  try {
    const { id } = req.params;
    const { schedule } = req.body;
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        schedule: schedule,
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      res.json({ success: true, message: 'Schedule updated', schedule: truck.schedule });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error updating schedule:', error);
    res.status(500).json({ message: 'Error updating schedule' });
  }
});

// ===== ANALYTICS ROUTES =====
// Get analytics data for a food truck
app.get('/api/trucks/:id/analytics', async (req, res) => {
  try {
    const { id } = req.params;
    const truck = await FoodTruck.findOne({ id });
    
    if (truck) {
      // Mock analytics data - in production this would come from real data
      const analytics = {
        totalViews: Math.floor(Math.random() * 1000) + 100,
        totalFavorites: await Favorite.countDocuments({ truckId: id }),
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
  } catch (error) {
    logger.error('❌ Error fetching analytics:', error);
    res.status(500).json({ message: 'Error fetching analytics' });
  }
});

// ===== POS INTEGRATION ROUTES =====
// Get POS settings for owner
app.get('/api/pos/settings/:ownerId', async (req, res) => {
  try {
    const { ownerId } = req.params;
    const truck = await FoodTruck.findOne({ ownerId });
    
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
  } catch (error) {
    logger.error('❌ Error fetching POS settings:', error);
    res.status(500).json({ message: 'Error fetching POS settings' });
  }
});

// Create child POS account
app.post('/api/pos/child-account', async (req, res) => {
  try {
    const { parentOwnerId, childAccountName, permissions } = req.body;
    
    const truck = await FoodTruck.findOne({ ownerId: parentOwnerId });
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
    await truck.save();
    
    logger.info(`✅ Created child POS account: ${childAccountName} for ${truck.name}`);
    res.json({ success: true, childAccount });
  } catch (error) {
    logger.error('❌ Error creating child account:', error);
    res.status(500).json({ message: 'Error creating child account' });
  }
});

// POS location update (from child account)
app.post('/api/pos/location-update', async (req, res) => {
  try {
    const { apiKey, latitude, longitude, address, isOpen } = req.body;
    
    // Find truck by child API key
    const truck = await FoodTruck.findOne({
      'posSettings.childAccounts.apiKey': apiKey,
      'posSettings.childAccounts.isActive': true
    });
    
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
      lastUpdated: new Date()
    };
    
    if (typeof isOpen === 'boolean') {
      updates.isOpen = isOpen;
    }
    
    await FoodTruck.findOneAndUpdate({ id: truck.id }, updates);
    
    logger.info(`📍 POS location update for ${truck.name}: ${latitude}, ${longitude}`);
    res.json({ success: true, message: 'Location updated via POS' });
  } catch (error) {
    logger.error('❌ Error updating location via POS:', error);
    res.status(500).json({ message: 'Error updating location via POS' });
  }
});

// Get child accounts for owner
app.get('/api/pos/child-accounts/:ownerId', async (req, res) => {
  try {
    const { ownerId } = req.params;
    const truck = await FoodTruck.findOne({ ownerId });
    
    if (!truck || !truck.posSettings) {
      return res.json({ success: true, childAccounts: [] });
    }
    
    res.json({ success: true, childAccounts: truck.posSettings.childAccounts });
  } catch (error) {
    logger.error('❌ Error fetching child accounts:', error);
    res.status(500).json({ message: 'Error fetching child accounts' });
  }
});

// Deactivate child account
app.put('/api/pos/child-account/:childId/deactivate', async (req, res) => {
  try {
    const { childId } = req.params;
    const { ownerId } = req.body;
    
    const truck = await FoodTruck.findOne({ ownerId });
    if (!truck || !truck.posSettings) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    const childAccount = truck.posSettings.childAccounts.find(child => child.id === childId);
    if (!childAccount) {
      return res.status(404).json({ message: 'Child account not found' });
    }
    
    childAccount.isActive = false;
    await truck.save();
    
    logger.info(`🚫 Deactivated child POS account: ${childAccount.name}`);
    res.json({ success: true, message: 'Child account deactivated' });
  } catch (error) {
    logger.error('❌ Error deactivating child account:', error);
    res.status(500).json({ message: 'Error deactivating child account' });
  }
});

// ===== FAVORITES ROUTES =====
// Get user's favorite food trucks
app.get('/api/users/:userId/favorites', async (req, res) => {
  try {
    const { userId } = req.params;
    logger.debug(`❤️  Getting favorites for user: ${userId}`);
    
    const favorites = await Favorite.find({ userId });
    const favoriteIds = favorites.map(fav => fav.truckId);
    const favoriteTrucks = await FoodTruck.find({ id: { $in: favoriteIds } });
    
    logger.info(`❤️  Found ${favoriteTrucks.length} favorites for user ${userId}`);
    res.json(favoriteTrucks);
  } catch (error) {
    logger.error('❌ Error fetching favorites:', error);
    res.status(500).json({ message: 'Error fetching favorites' });
  }
});

// Add food truck to favorites
app.post('/api/users/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    logger.debug(`❤️  Adding truck ${truckId} to favorites for user ${userId}`);
    
    const favorite = new Favorite({ userId, truckId });
    await favorite.save();
    
    logger.info(`❤️  Favorite added successfully`);
    res.json({ success: true, message: 'Food truck added to favorites' });
  } catch (error) {
    if (error.code === 11000) {
      // Duplicate key error - already favorited
      res.json({ success: true, message: 'Food truck already in favorites' });
    } else {
      logger.error('❌ Error adding favorite:', error);
      res.status(500).json({ message: 'Error adding to favorites' });
    }
  }
});

// Remove food truck from favorites
app.delete('/api/users/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    logger.debug(`💔 Removing truck ${truckId} from favorites for user ${userId}`);
    
    await Favorite.deleteOne({ userId, truckId });
    
    logger.info(`💔 Favorite removed successfully`);
    res.json({ success: true, message: 'Food truck removed from favorites' });
  } catch (error) {
    logger.error('❌ Error removing favorite:', error);
    res.status(500).json({ message: 'Error removing from favorites' });
  }
});

// Check if food truck is in favorites
app.get('/api/users/:userId/favorites/check/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    const favorite = await Favorite.findOne({ userId, truckId });
    const isFavorite = !!favorite;
    logger.debug(`❤️  Checking if truck ${truckId} is favorite for user ${userId}: ${isFavorite}`);
    res.json({ isFavorite });
  } catch (error) {
    logger.error('❌ Error checking favorite:', error);
    res.status(500).json({ message: 'Error checking favorite status' });
  }
});

// Password Reset Routes - FIX FOR BUG #6
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    
    logger.info(`🔐 Password reset request for: ${email}`);
    
    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
      logger.warn(`❌ Password reset failed: User ${email} not found`);
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Generate reset token (in production, use crypto.randomBytes)
    const resetToken = `reset_${user._id}_${Date.now()}`;
    
    // In production, you would:
    // 1. Store the token in database with expiration
    // 2. Send email with reset link
    // For now, we'll just return success message
    
    logger.info(`✅ Password reset token generated for: ${email}`);
    logger.debug(`🔗 Reset token: ${resetToken}`);
    
    res.json({
      success: true,
      message: 'Password reset instructions sent to your email',
      // In production, don't return the token
      resetToken: resetToken // Only for development/testing
    });
    
  } catch (error) {
    logger.error('❌ Forgot password error:', error);
    res.status(500).json({ success: false, message: 'Server error during password reset request' });
  }
});

app.post('/api/auth/reset-password', async (req, res) => {
  try {
    const { resetToken, newPassword } = req.body;
    
    logger.debug(`🔐 Password reset attempt with token: ${resetToken}`);
    
    if (!resetToken || !newPassword) {
      return res.status(400).json({ success: false, message: 'Reset token and new password are required' });
    }
    
    // Extract user ID from token (in production, validate token from database)
    const tokenParts = resetToken.split('_');
    if (tokenParts.length !== 3 || tokenParts[0] !== 'reset') {
      return res.status(400).json({ success: false, message: 'Invalid reset token' });
    }
    
    const userId = tokenParts[1];
    const user = await User.findOne({ _id: userId });
    
    if (!user) {
      logger.warn(`❌ Password reset failed: User not found for token`);
      return res.status(404).json({ success: false, message: 'Invalid reset token' });
    }
    
    // Update password (in production, hash the password)
    await User.findByIdAndUpdate(userId, { password: newPassword });
    
    logger.info(`✅ Password reset successful for user: ${user.email}`);
    
    res.json({
      success: true,
      message: 'Password reset successful'
    });
    
  } catch (error) {
    logger.error('❌ Reset password error:', error);
    res.status(500).json({ success: false, message: 'Server error during password reset' });
  }
});

// Email Change Routes - ENHANCED with flexible user lookup

// Mobile app compatible route: PUT /api/users/:userId/email
app.put('/api/users/:userId/email', async (req, res) => {
  logger.debug('\n📧 Mobile email change request received');
  logger.debug('Request body:', JSON.stringify(req.body, null, 2));
  logger.debug('User ID from params:', req.params.userId);
  
  try {
    const { userId } = req.params;
    const { newEmail, password } = req.body;
    
    if (!userId || !newEmail || !password) {
      logger.warn('❌ Missing required fields');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: userId, newEmail, password'
      });
    }
    
    // Use flexible user finder
    const user = await findUserFlexibly(userId);
    if (!user) {
      logger.warn(`❌ User not found for identifier: ${userId}`);
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    logger.debug(`✅ User found: ${user.userId || user._id} (${user.email})`);
    
    // Verify password
    if (user.password !== password) {
      logger.warn('❌ Password is incorrect');
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    logger.debug('✅ Password verified');
    
    // Check if new email is already in use
    const existingUser = await User.findOne({ email: newEmail });
    if (existingUser && existingUser._id.toString() !== user._id.toString()) {
      logger.warn(`❌ Email change failed: Email ${newEmail} already in use`);
      return res.status(400).json({ success: false, message: 'Email already in use' });
    }
    
    // Update email directly (for mobile app compatibility)
    logger.debug(`🔄 Attempting to update email for user: ${user._id}`);
    logger.debug(`🔄 User _id type: ${typeof user._id}`);
    logger.debug(`🔄 User _id value: ${user._id}`);
    
    const updateResult = await User.findOneAndUpdate(
      { _id: user._id },
      { email: newEmail },
      { new: true }
    );
    
    logger.debug(`📧 Update result: ${updateResult ? 'SUCCESS' : 'FAILED'}`);
    logger.debug(`📧 New email in database: ${updateResult ? updateResult.email : 'N/A'}`);
    
    if (updateResult) {
      logger.info(`✅ Email change successful: ${user.email} -> ${newEmail}`);
      
      // Send email change notification
      emailService.sendEmailChangeNotification(user.email, newEmail, user.name).catch(err => {
        logger.error('Failed to send email change notification:', err);
      });
      
      res.json({
        success: true,
        message: 'Email changed successfully',
        user: {
          _id: updateResult._id.toString(),
          id: updateResult._id.toString(),
          userId: updateResult._id.toString(),
          name: updateResult.name,
          email: updateResult.email,
          role: updateResult.role,
          businessName: updateResult.businessName
        }
      });
    } else {
      logger.error(`❌ Email update failed for user: ${user.email}`);
      logger.debug('🔍 Trying alternative email update method...');
      
      // Try alternative update method using the original search criteria
      const alternativeQuery = user.userId ? { userId: user.userId } : { _id: user._id };
      logger.debug(`🔄 Alternative query: ${JSON.stringify(alternativeQuery)}`);
      
      const alternativeUpdate = await User.findOneAndUpdate(
        alternativeQuery,
        { email: newEmail },
        { new: true }
      );
      
      if (alternativeUpdate) {
        logger.info('✅ Alternative email update method succeeded');
        logger.info(`✅ Email updated successfully in database using alternative method`);
        
        res.json({
          success: true,
          message: 'Email changed successfully',
          user: {
            _id: alternativeUpdate._id.toString(),
            id: alternativeUpdate._id.toString(),
            userId: alternativeUpdate._id.toString(),
            name: alternativeUpdate.name,
            email: alternativeUpdate.email,
            role: alternativeUpdate.role,
            businessName: alternativeUpdate.businessName
          }
        });
      } else {
        logger.error('❌ Alternative email update method also failed');
        res.status(500).json({ success: false, message: 'Failed to update email in database' });
      }
    }
    
  } catch (error) {
    logger.error('❌ Change email error:', error);
    res.status(500).json({ success: false, message: 'Server error during email change request' });
  }
});

// Legacy route for web portal compatibility
app.post('/api/users/change-email', async (req, res) => {
  logger.debug('\n📧 Email change request received');
  logger.debug('Request body:', JSON.stringify(req.body, null, 2));
  
  try {
    const { userId, newEmail, password } = req.body;
    
    if (!userId || !newEmail || !password) {
      logger.warn('❌ Missing required fields');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: userId, newEmail, password'
      });
    }
    
    // Use flexible user finder
    const user = await findUserFlexibly(userId);
    if (!user) {
      logger.warn(`❌ User not found for identifier: ${userId}`);
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    logger.debug(`✅ User found: ${user.userId || user._id} (${user.email})`);
    
    // Verify password
    if (user.password !== password) {
      logger.warn('❌ Password is incorrect');
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }
    
    logger.debug('✅ Password verified');
    
    // Check if new email is already in use
    const existingUser = await User.findOne({ email: newEmail });
    if (existingUser && existingUser._id !== userId) {
      logger.warn(`❌ Email change failed: Email ${newEmail} already in use`);
      return res.status(400).json({ success: false, message: 'Email already in use' });
    }
    
    // Generate verification token (in production, use crypto.randomBytes)
    const verificationToken = `email_change_${userId}_${Date.now()}`;
    
    // In production, you would:
    // 1. Store the pending email change in database
    // 2. Send verification email to new email address
    // For now, we'll just return success message
    
    logger.info(`✅ Email change verification token generated for: ${user.email} -> ${newEmail}`);
    logger.debug(`🔗 Verification token: ${verificationToken}`);
    
    res.json({
      success: true,
      message: 'Email change verification sent to new email address',
      // In production, don't return the token
      verificationToken: verificationToken // Only for development/testing
    });
    
  } catch (error) {
    logger.error('❌ Change email error:', error);
    res.status(500).json({ success: false, message: 'Server error during email change request' });
  }
});

app.post('/api/users/verify-email-change', async (req, res) => {
  try {
    const { verificationToken, newEmail } = req.body;
    
    logger.debug(`📧 Email change verification with token: ${verificationToken}`);
    logger.debug(`📧 New email: ${newEmail}`);
    
    if (!verificationToken || !newEmail) {
      return res.status(400).json({ success: false, message: 'Verification token and new email are required' });
    }
    
    // Extract user ID from token (in production, validate token from database)
    const tokenParts = verificationToken.split('_');
    if (tokenParts.length !== 4 || tokenParts[0] !== 'email' || tokenParts[1] !== 'change') {
      return res.status(400).json({ success: false, message: 'Invalid verification token' });
    }
    
    const userId = tokenParts[2];
    logger.debug(`📧 Extracted user ID from token: ${userId}`);
    
    // Use flexible user finder
    const user = await findUserFlexibly(userId);
    logger.debug(`📧 User found: ${user ? user.email : 'NOT FOUND'}`);
    
    if (!user) {
      logger.warn(`❌ Email change verification failed: User not found`);
      return res.status(404).json({ success: false, message: 'Invalid verification token' });
    }
    
    logger.debug(`📧 Current email: ${user.email}`);
    logger.debug(`📧 New email: ${newEmail}`);
    
    // Update email using findOneAndUpdate for better control
    const updateResult = await User.findOneAndUpdate(
      { _id: userId },
      { email: newEmail },
      { new: true }
    );
    
    logger.debug(`📧 Update result: ${updateResult ? 'SUCCESS' : 'FAILED'}`);
    logger.debug(`📧 New email in database: ${updateResult ? updateResult.email : 'N/A'}`);
    
    if (updateResult) {
      logger.info(`✅ Email change successful: ${user.email} -> ${newEmail}`);
      
      // Send email change notification
      emailService.sendEmailChangeNotification(user.email, newEmail, user.name).catch(err => {
        logger.error('Failed to send email change notification:', err);
      });
      
      res.json({
        success: true,
        message: 'Email changed successfully',
        user: {
          _id: updateResult._id,
          name: updateResult.name,
          email: updateResult.email,
          role: updateResult.role,
          businessName: updateResult.businessName
        },
        debug: {
          userId: userId,
          oldEmail: user.email,
          newEmail: newEmail,
          updatedEmail: updateResult.email
        }
      });
    } else {
      logger.error(`❌ Email update failed for user: ${user.email}`);
      res.status(500).json({ success: false, message: 'Failed to update email in database' });
    }
    
  } catch (error) {
    logger.error('❌ Verify email change error:', error);
    res.status(500).json({ success: false, message: 'Server error during email verification' });
  }
});

// Enhanced user finder function that handles ID mismatches
async function findUserFlexibly(identifier) {
  logger.debug(`🔍 Searching for user with identifier: ${identifier}`);
  
  // Try exact userId match first
  let user = await User.findOne({ userId: identifier });
  if (user) {
    logger.debug(`✅ Found user by exact userId match: ${user.userId}`);
    return user;
  }
  
  // Try _id field match (for default users)
  user = await User.findOne({ _id: identifier });
  if (user) {
    logger.debug(`✅ Found user by _id match: ${user._id}`);
    return user;
  }
  
  // Try email match
  user = await User.findOne({ email: identifier });
  if (user) {
    logger.debug(`✅ Found user by email match: ${user.email}`);
    return user;
  }
  
  // Try partial userId match (for timestamp-based IDs)
  user = await User.findOne({ userId: { $regex: identifier.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), $options: 'i' } });
  if (user) {
    logger.debug(`✅ Found user by partial userId match: ${user.userId}`);
    return user;
  }
  
  // Try MongoDB ObjectId if it looks like one
  if (identifier.match(/^[0-9a-fA-F]{24}$/)) {
    try {
      user = await User.findById(identifier);
      if (user) {
        logger.debug(`✅ Found user by ObjectId match: ${user._id}`);
        return user;
      }
    } catch (err) {
      logger.debug(`❌ Invalid ObjectId: ${identifier}`);
    }
  }
  
  logger.debug(`❌ No user found for identifier: ${identifier}`);
  return null;
}

// Mobile app compatible password change route: PUT /api/users/:userId/password
app.put('/api/users/:userId/password', async (req, res) => {
  logger.debug('\n🔐 Mobile password change request received');
  logger.debug('Request body:', JSON.stringify(req.body, null, 2));
  logger.debug('User ID from params:', req.params.userId);
  
  try {
    const { userId } = req.params;
    const { currentPassword, newPassword } = req.body;
    
    if (!userId || !currentPassword || !newPassword) {
      logger.warn('❌ Missing required fields');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: userId (in URL), currentPassword, newPassword'
      });
    }
    
    // Use flexible user finder
    const user = await findUserFlexibly(userId);
    
    if (!user) {
      logger.warn(`❌ User not found for identifier: ${userId}`);
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    logger.debug(`✅ User found: ${user.userId || user._id} (${user.email})`);
    
    // Verify current password
    if (user.password !== currentPassword) {
      logger.warn('❌ Current password is incorrect');
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }
    
    logger.debug('✅ Current password verified');
    
    // Validate new password requirements
    const passwordValidation = validatePassword(newPassword);
    if (!passwordValidation.isValid) {
      logger.warn(`❌ Password change failed: New password does not meet requirements`);
      return res.status(400).json({ 
        success: false, 
        message: 'New password does not meet requirements',
        passwordRequirements: getPasswordRequirements(),
        currentPassword: {
          length: passwordValidation.requirements.length,
          hasUppercase: passwordValidation.requirements.hasUppercase,
          hasLowercase: passwordValidation.requirements.hasLowercase,
          hasNumbers: passwordValidation.requirements.hasNumbers,
          hasSpecialChars: passwordValidation.requirements.hasSpecialChars
        }
      });
    }
    
    // Update password directly (for mobile app compatibility)
    logger.debug(`🔄 Attempting to update password for user: ${user._id}`);
    logger.debug(`🔄 User _id type: ${typeof user._id}`);
    logger.debug(`🔄 User _id value: ${user._id}`);
    
    const updatedUser = await User.findOneAndUpdate(
      { _id: user._id },
      { password: newPassword },
      { new: true }
    );
    
    logger.debug(`🔄 Update result: ${updatedUser ? 'SUCCESS' : 'FAILED'}`);
    if (updatedUser) {
      logger.debug(`🔄 Updated user _id: ${updatedUser._id}`);
      logger.debug(`🔄 Updated user password: ${updatedUser.password ? 'SET' : 'NOT SET'}`);
    }
    
    if (!updatedUser) {
      logger.error('❌ Failed to update password in database');
      logger.debug('🔍 Trying alternative update method...');
      
      // Try alternative update method using the original search criteria
      const alternativeQuery = user.userId ? { userId: user.userId } : { _id: user._id };
      logger.debug(`🔄 Alternative query: ${JSON.stringify(alternativeQuery)}`);
      
      const alternativeUpdate = await User.findOneAndUpdate(
        alternativeQuery,
        { password: newPassword },
        { new: true }
      );
      
      if (alternativeUpdate) {
        logger.info('✅ Alternative update method succeeded');
        logger.info(`✅ Password updated successfully in database using alternative method`);
        
        res.json({
          success: true,
          message: 'Password changed successfully',
          user: {
            _id: alternativeUpdate._id.toString(),
            id: alternativeUpdate._id.toString(),
            userId: alternativeUpdate._id.toString(),
            email: alternativeUpdate.email,
            name: alternativeUpdate.name,
            role: alternativeUpdate.role,
            businessName: alternativeUpdate.businessName
          }
        });
        return;
      } else {
        logger.error('❌ Alternative update method also failed');
        return res.status(500).json({
          success: false,
          message: 'Failed to update password'
        });
      }
    }
    
    logger.info('✅ Password updated successfully in database');
    
    res.json({
      success: true,
      message: 'Password changed successfully',
      user: {
        _id: updatedUser._id.toString(),
        id: updatedUser._id.toString(),
        userId: updatedUser._id.toString(),
        email: updatedUser.email,
        name: updatedUser.name,
        role: updatedUser.role,
        businessName: updatedUser.businessName
      }
    });
    
  } catch (error) {
    logger.error('❌ Password change error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Legacy password change endpoint - ENHANCED with flexible user lookup
app.post('/api/users/change-password', async (req, res) => {
  logger.debug('\n🔐 Password change request received');
  logger.debug('Request body:', JSON.stringify(req.body, null, 2));
  
  try {
    const { userId, currentPassword, newPassword } = req.body;
    
    if (!userId || !currentPassword || !newPassword) {
      logger.warn('❌ Missing required fields');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: userId, currentPassword, newPassword'
      });
    }
    
    // Use flexible user finder
    const user = await findUserFlexibly(userId);
    
    if (!user) {
      logger.warn(`❌ User not found for identifier: ${userId}`);
      
      // Debug: Show all users to help identify the issue
      const allUsers = await User.find({}, 'userId _id email role').limit(10);
      logger.debug('📋 Available users in database:');
      allUsers.forEach(u => {
        logger.debug(`   userId: ${u.userId || 'undefined'} | _id: ${u._id} | email: ${u.email} | role: ${u.role}`);
      });
      
      return res.status(404).json({
        success: false,
        message: 'User not found',
        debug: {
          searchedFor: userId,
          availableUsers: allUsers.map(u => ({
            userId: u.userId,
            _id: u._id.toString(),
            email: u.email
          }))
        }
      });
    }
    
    logger.debug(`✅ User found: ${user.userId || user._id} (${user.email})`);
    
    // Verify current password
    if (user.password !== currentPassword) {
      logger.warn('❌ Current password is incorrect');
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }
    
    logger.debug('✅ Current password verified');
    
    // Validate new password requirements
    const passwordValidation = validatePassword(newPassword);
    if (!passwordValidation.isValid) {
      logger.warn(`❌ Password change failed: New password does not meet requirements`);
      return res.status(400).json({ 
        success: false, 
        message: 'New password does not meet requirements',
        passwordRequirements: getPasswordRequirements(),
        currentPassword: {
          length: passwordValidation.requirements.length,
          hasUppercase: passwordValidation.requirements.hasUppercase,
          hasLowercase: passwordValidation.requirements.hasLowercase,
          hasNumbers: passwordValidation.requirements.hasNumbers,
          hasSpecialChars: passwordValidation.requirements.hasSpecialChars
        }
      });
    }
    
    // Update password using both userId and _id for maximum compatibility
    const updateQuery = user.userId ? { userId: user.userId } : { _id: user._id };
    const updatedUser = await User.findOneAndUpdate(
      updateQuery,
      { password: newPassword },
      { new: true }
    );
    
    if (!updatedUser) {
      logger.error('❌ Failed to update password in database');
      return res.status(500).json({
        success: false,
        message: 'Failed to update password'
      });
    }
    
    logger.info('✅ Password updated successfully in database');
    
    res.json({
      success: true,
      message: 'Password changed successfully',
      user: {
        userId: updatedUser.userId || updatedUser._id.toString(),
        email: updatedUser.email,
        name: updatedUser.name
      }
    });
    
  } catch (error) {
    logger.error('❌ Password change error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Search food trucks
app.get('/api/trucks/search', async (req, res) => {
  try {
    const query = req.query.q?.toLowerCase() || '';
    const trucks = await FoodTruck.find({
      $or: [
        { name: { $regex: query, $options: 'i' } },
        { description: { $regex: query, $options: 'i' } },
        { cuisine: { $regex: query, $options: 'i' } }
      ]
    });
    logger.info(`🔍 Search for "${query}" found ${trucks.length} trucks`);
    res.json(trucks);
  } catch (error) {
    logger.error('❌ Error searching trucks:', error);
    res.status(500).json({ message: 'Error searching food trucks' });
  }
});

// Enhanced filtering endpoint for mobile app
app.get('/api/trucks/filter', async (req, res) => {
  try {
    const {
      search,
      cuisine,
      cuisines, // Support multiple cuisines (comma-separated)
      openOnly,
      minRating,
      lat,
      lng,
      maxDistance, // in kilometers
      sortBy, // distance, rating, name, reviewCount
      limit = 50
    } = req.query;

    let query = { isActive: true };
    let sort = {};

    // Text search
    if (search) {
      const searchRegex = new RegExp(search, 'i');
      query.$or = [
        { name: searchRegex },
        { description: searchRegex },
        { cuisine: searchRegex },
        { businessName: searchRegex }
      ];
    }

    // Cuisine filtering (single or multiple)
    if (cuisine || cuisines) {
      const cuisineList = cuisines ? cuisines.split(',').map(c => c.trim()) : [cuisine];
      if (cuisineList.length === 1) {
        query.cuisine = new RegExp(cuisineList[0], 'i');
      } else {
        query.cuisine = { $in: cuisineList.map(c => new RegExp(c, 'i')) };
      }
    }

    // Open now filtering
    if (openOnly === 'true') {
      query.isOpen = true;
    }

    // Rating filtering
    if (minRating) {
      query.rating = { $gte: parseFloat(minRating) };
    }

    // Distance filtering (basic implementation)
    let trucks = await FoodTruck.find(query);

    // Update open/closed status based on current time and schedule
    trucks = trucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule)
    }));

    // Apply distance filtering if coordinates provided
    if (lat && lng && maxDistance) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      const maxDistanceKm = parseFloat(maxDistance);

      trucks = trucks.filter(truck => {
        if (!truck.location?.latitude || !truck.location?.longitude) {
          return false; // Exclude trucks without location
        }

        // Calculate distance using Haversine formula
        const truckLat = truck.location.latitude;
        const truckLng = truck.location.longitude;
        
        const R = 6371; // Earth's radius in km
        const dLat = (truckLat - userLat) * Math.PI / 180;
        const dLng = (truckLng - userLng) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                  Math.cos(userLat * Math.PI / 180) * Math.cos(truckLat * Math.PI / 180) *
                  Math.sin(dLng/2) * Math.sin(dLng/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const distance = R * c;

        // Add distance to truck object for sorting
        truck.distance = distance;
        
        return distance <= maxDistanceKm;
      });
    }

    // Apply sorting
    switch (sortBy) {
      case 'distance':
        if (lat && lng) {
          trucks.sort((a, b) => (a.distance || Infinity) - (b.distance || Infinity));
        }
        break;
      case 'rating':
        trucks.sort((a, b) => (b.rating || 0) - (a.rating || 0));
        break;
      case 'name':
        trucks.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
        break;
      case 'reviewCount':
        trucks.sort((a, b) => (b.reviewCount || 0) - (a.reviewCount || 0));
        break;
      default:
        // Default sort by lastUpdated
        trucks.sort((a, b) => new Date(b.lastUpdated) - new Date(a.lastUpdated));
    }

    // Apply limit
    trucks = trucks.slice(0, parseInt(limit));

    logger.info(`🔍 Enhanced filter found ${trucks.length} trucks`);
    res.json(trucks);
    
  } catch (error) {
    logger.error('❌ Error filtering trucks:', error);
    res.status(500).json({ message: 'Error filtering food trucks' });
  }
});

// Get available filter options for mobile app
app.get('/api/trucks/filters', async (req, res) => {
  try {
    // Get distinct cuisine types
    const cuisines = await FoodTruck.distinct('cuisine');
    
    // Get location-based stats
    const stats = await FoodTruck.aggregate([
      { $match: { isActive: true } },
      {
        $group: {
          _id: null,
          totalTrucks: { $sum: 1 },
          averageRating: { $avg: '$rating' },
          openTrucks: {
            $sum: { $cond: [{ $eq: ['$isOpen', true] }, 1, 0] }
          }
        }
      }
    ]);

    const filterOptions = {
      cuisines: cuisines.filter(cuisine => cuisine && cuisine.trim()),
      stats: stats[0] || { totalTrucks: 0, averageRating: 0, openTrucks: 0 }
    };

    logger.info(`📊 Filter options: ${filterOptions.cuisines.length} cuisines available`);
    res.json(filterOptions);
    
  } catch (error) {
    logger.error('❌ Error getting filter options:', error);
    res.status(500).json({ message: 'Error getting filter options' });
  }
});

// Get nearby food trucks
app.get('/api/trucks/nearby', async (req, res) => {
  try {
    const { lat, lng, radius = 5 } = req.query;
    // For simplicity, return all trucks (in real app, calculate distance)
    const trucks = await FoodTruck.find();
    logger.info(`📍 Nearby search: lat=${lat}, lng=${lng}, radius=${radius}km`);
    res.json(trucks);
  } catch (error) {
    logger.error('❌ Error fetching nearby trucks:', error);
    res.status(500).json({ message: 'Error fetching nearby trucks' });
  }
});

// Add new food truck (for owners)
app.post('/api/trucks', verifyToken, sanitizeInput, validateCreateTruck, asyncHandler(async (req, res) => {
  try {
    const newTruck = new FoodTruck({
      id: `truck_${Date.now()}`,
      ...req.body,
      createdAt: new Date(),
      lastUpdated: new Date(),
      rating: 0,
      reviewCount: 0
    });
    
    await newTruck.save();
    logger.info(`🚚 New truck created: ${newTruck.name}`);
    res.json({ success: true, truck: newTruck });
  } catch (error) {
    logger.error('❌ Error creating truck:', error);
    res.status(500).json({ message: 'Error creating food truck' });
  }
}));

// Update food truck (for owners)
app.put('/api/trucks/:id', async (req, res) => {
  try {
    const updates = {
      ...req.body,
      lastUpdated: new Date()
    };
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id: req.params.id },
      updates,
      { new: true }
    );
    
    if (truck) {
      logger.info(`✅ Updated food truck: ${truck.name} (ID: ${req.params.id})`);
      res.json({ success: true, truck });
    } else {
      logger.warn(`❌ Truck ${req.params.id} not found for update`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error updating truck:', error);
    res.status(500).json({ message: 'Error updating food truck' });
  }
});

// Get food truck cover photo
app.get('/api/trucks/:id/cover-photo', async (req, res) => {
  try {
    const { id } = req.params;
    const truck = await FoodTruck.findOne({ id });
    
    if (truck) {
      res.json({ imageUrl: truck.image || null });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error fetching cover photo:', error);
    res.status(500).json({ message: 'Error fetching cover photo' });
  }
});

// ===== MENU MANAGEMENT ROUTES =====
// Update menu items for a food truck
app.put('/api/trucks/:id/menu', async (req, res) => {
  try {
    const { id } = req.params;
    const { menu } = req.body;
    
    logger.debug(`🍽️ Menu update request for truck ${id}`);
    logger.debug(`🍽️ Menu items: ${menu?.length || 0}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        menu: menu || [],
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      logger.info(`✅ Menu updated for ${truck.name} - ${truck.menu.length} items`);
      res.json({ success: true, message: 'Menu updated', menu: truck.menu });
    } else {
      logger.warn(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    logger.error('❌ Error updating menu:', error);
    res.status(500).json({ message: 'Error updating menu' });
  }
});

// Debug endpoint to check current time logic
app.get('/api/debug/time', async (req, res) => {
  try {
    const now = new Date();
    const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    const currentDay = dayNames[now.getDay()];
    const currentTime = now.getHours().toString().padStart(2, '0') + ':' + now.getMinutes().toString().padStart(2, '0');
    
    // Get all trucks and check their open status
    const trucks = await FoodTruck.find({});
    const truckStatus = trucks.map(truck => {
      const todaySchedule = truck.schedule[currentDay];
      const isOpen = isCurrentlyOpen(truck.schedule);
      
      return {
        id: truck.id,
        name: truck.name,
        todaySchedule: todaySchedule,
        isCurrentlyOpen: isOpen,
        currentTime: currentTime,
        currentDay: currentDay
      };
    });
    
    res.json({
      success: true,
      debug: {
        serverTime: now.toISOString(),
        localTime: now.toString(),
        currentDay: currentDay,
        currentTime: currentTime,
        dayOfWeek: now.getDay(),
        timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone
      },
      truckStatus: truckStatus
    });
  } catch (error) {
    res.status(500).json({ message: 'Error checking time debug info', error: error.message });
  }
});

// ===== REVIEW MANAGEMENT ROUTES =====

// Get reviews for a specific food truck
app.get('/api/trucks/:id/reviews', async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 10, sortBy = 'createdAt' } = req.query;
    
    const reviews = await Review.find({ truckId: id })
      .sort({ [sortBy]: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();
    
    // Add hasUserVotedHelpful field for authenticated users
    const userId = req.headers.authorization ? 
      (await verifyTokenNoMiddleware(req.headers.authorization))?.id : null;
    
    const reviewsWithVoteStatus = reviews.map(review => {
      const reviewObj = review.toObject();
      reviewObj.hasUserVotedHelpful = userId ? review.hasUserVotedHelpful(userId) : false;
      return reviewObj;
    });
    
    const totalReviews = await Review.countDocuments({ truckId: id });
    const stats = await Review.getStatsForTruck(id);
    
    logger.info(`📋 Retrieved ${reviews.length} reviews for truck ${id}`);
    
    res.json({
      success: true,
      reviews: reviewsWithVoteStatus,
      stats,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(totalReviews / limit),
        totalReviews
      }
    });
  } catch (error) {
    logger.error('❌ Error fetching reviews:', error);
    res.status(500).json({ message: 'Error fetching reviews' });
  }
});

// Add a new review
app.post('/api/trucks/:id/reviews', verifyToken, sanitizeInput, validateCreateReview, asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, comment, photos = [] } = req.body;
    const userId = req.user.id;
    
    // Check if user has already reviewed this truck
    const existingReview = await Review.findOne({ userId, truckId: id });
    if (existingReview) {
      return res.status(400).json({ 
        success: false, 
        message: 'You have already reviewed this food truck' 
      });
    }
    
    // Get user details
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }
    
    // Create new review
    const newReview = new Review({
      userId,
      userName: user.name,
      truckId: id,
      rating,
      comment,
      photos
    });
    
    await newReview.save();
    
    // Update truck rating and review count
    const stats = await Review.getStatsForTruck(id);
    await FoodTruck.findOneAndUpdate(
      { id },
      { 
        rating: stats.averageRating,
        reviewCount: stats.totalReviews,
        lastUpdated: new Date()
      }
    );
    
    logger.info(`⭐ New review added for truck ${id} by user ${userId}`);
    
    // Send notification email to truck owner
    const truck = await FoodTruck.findOne({ id });
    if (truck && truck.ownerId) {
      const owner = await User.findById(truck.ownerId);
      if (owner && owner.email) {
        emailService.sendNewReviewNotification(owner, truck, newReview).catch(err => {
          logger.error('Failed to send review notification email:', err);
        });
      }
    }
    
    res.json({
      success: true,
      message: 'Review added successfully',
      review: newReview
    });
  } catch (error) {
    logger.error('❌ Error adding review:', error);
    res.status(500).json({ message: 'Error adding review' });
  }
}));

// ===== IMAGE UPLOAD ROUTE =====
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
    
    logger.info(`✅ Image uploaded for truck ${truck.name}`);
    
    res.json({
      success: true,
      imageUrl: req.file.path,
      message: 'Image uploaded successfully'
    });
  } catch (error) {
    logger.error('❌ Upload error:', error);
    res.status(500).json({ message: 'Upload failed' });
  }
});

// Update a review
app.put('/api/reviews/:reviewId', verifyToken, async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { rating, comment, photos } = req.body;
    const userId = req.user.id;
    
    const review = await Review.findById(reviewId);
    
    if (!review) {
      return res.status(404).json({ 
        success: false, 
        message: 'Review not found' 
      });
    }
    
    // Check if user owns this review
    if (review.userId.toString() !== userId) {
      return res.status(403).json({ 
        success: false, 
        message: 'You can only edit your own reviews' 
      });
    }
    
    // Update review
    review.rating = rating || review.rating;
    review.comment = comment || review.comment;
    review.photos = photos || review.photos;
    
    await review.save();
    
    // Update truck rating
    const stats = await Review.getStatsForTruck(review.truckId);
    await FoodTruck.findOneAndUpdate(
      { id: review.truckId },
      { 
        rating: stats.averageRating,
        lastUpdated: new Date()
      }
    );
    
    logger.info(`✏️ Review ${reviewId} updated`);
    
    res.json({
      success: true,
      message: 'Review updated successfully',
      review
    });
  } catch (error) {
    logger.error('❌ Error updating review:', error);
    res.status(500).json({ message: 'Error updating review' });
  }
});

// Delete a review
app.delete('/api/reviews/:reviewId', verifyToken, async (req, res) => {
  try {
    const { reviewId } = req.params;
    const userId = req.user.id;
    
    const review = await Review.findById(reviewId);
    
    if (!review) {
      return res.status(404).json({ 
        success: false, 
        message: 'Review not found' 
      });
    }
    
    // Check if user owns this review or is admin
    if (review.userId.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ 
        success: false, 
        message: 'You can only delete your own reviews' 
      });
    }
    
    const truckId = review.truckId;
    await review.deleteOne();
    
    // Update truck rating
    const stats = await Review.getStatsForTruck(truckId);
    await FoodTruck.findOneAndUpdate(
      { id: truckId },
      { 
        rating: stats.averageRating,
        reviewCount: stats.totalReviews,
        lastUpdated: new Date()
      }
    );
    
    logger.info(`🗑️ Review ${reviewId} deleted`);
    
    res.json({
      success: true,
      message: 'Review deleted successfully'
    });
  } catch (error) {
    logger.error('❌ Error deleting review:', error);
    res.status(500).json({ message: 'Error deleting review' });
  }
});

// Mark review as helpful
app.post('/api/reviews/:reviewId/helpful', verifyToken, async (req, res) => {
  try {
    const { reviewId } = req.params;
    const userId = req.user.id;
    
    const review = await Review.findById(reviewId);
    
    if (!review) {
      return res.status(404).json({ 
        success: false, 
        message: 'Review not found' 
      });
    }
    
    // Check if user has already voted
    if (review.hasUserVotedHelpful(userId)) {
      return res.status(400).json({ 
        success: false, 
        message: 'You have already marked this review as helpful' 
      });
    }
    
    // Add vote
    review.helpfulVotes.push({ userId });
    review.helpfulCount += 1;
    await review.save();
    
    logger.info(`👍 Review ${reviewId} marked as helpful by user ${userId}`);
    
    res.json({
      success: true,
      message: 'Review marked as helpful',
      helpfulCount: review.helpfulCount
    });
  } catch (error) {
    logger.error('❌ Error marking review as helpful:', error);
    res.status(500).json({ message: 'Error marking review as helpful' });
  }
});

// Get user's reviews
app.get('/api/users/:userId/reviews', async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    
    const reviews = await Review.find({ userId })
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();
    
    const totalReviews = await Review.countDocuments({ userId });
    
    logger.info(`📋 Retrieved ${reviews.length} reviews for user ${userId}`);
    
    res.json({
      success: true,
      reviews,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(totalReviews / limit),
        totalReviews
      }
    });
  } catch (error) {
    logger.error('❌ Error fetching user reviews:', error);
    res.status(500).json({ message: 'Error fetching user reviews' });
  }
});

// Owner response to review
app.post('/api/reviews/:reviewId/response', verifyToken, async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { text } = req.body;
    const userId = req.user.id;
    
    if (req.user.role !== 'owner') {
      return res.status(403).json({ 
        success: false, 
        message: 'Only food truck owners can respond to reviews' 
      });
    }
    
    const review = await Review.findById(reviewId);
    if (!review) {
      return res.status(404).json({ 
        success: false, 
        message: 'Review not found' 
      });
    }
    
    // Verify owner owns the truck being reviewed
    const truck = await FoodTruck.findOne({ id: review.truckId });
    if (!truck || truck.ownerId !== userId) {
      return res.status(403).json({ 
        success: false, 
        message: 'You can only respond to reviews for your own food truck' 
      });
    }
    
    // Add response
    review.response = {
      text,
      respondedAt: new Date(),
      respondedBy: req.user.name || 'Owner'
    };
    
    await review.save();
    
    logger.info(`💬 Owner responded to review ${reviewId}`);
    
    res.json({
      success: true,
      message: 'Response added successfully',
      review
    });
  } catch (error) {
    logger.error('❌ Error adding response:', error);
    res.status(500).json({ message: 'Error adding response' });
  }
});

// ===== SOCIAL MEDIA MANAGEMENT ROUTES =====

// Connect social media account
app.post('/api/social/accounts/connect', verifyToken, async (req, res) => {
  try {
    const { truckId, platform, accessToken, refreshToken, accountName, accountId, tokenExpiry } = req.body;
    const ownerId = req.user.id;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    // Create or update social account
    const socialAccount = await SocialAccount.findOneAndUpdate(
      { truckId, platform },
      {
        ownerId,
        truckId,
        platform,
        accessToken,
        refreshToken,
        accountName,
        accountId,
        tokenExpiry: tokenExpiry ? new Date(tokenExpiry) : null,
        isActive: true
      },
      { new: true, upsert: true }
    );
    
    logger.info(`✅ Connected ${platform} account for truck ${truckId}`);
    res.json({ success: true, account: socialAccount });
  } catch (error) {
    logger.error('❌ Error connecting social account:', error);
    res.status(500).json({ message: 'Error connecting social account' });
  }
});

// Get connected social accounts
app.get('/api/social/accounts/:truckId', verifyToken, async (req, res) => {
  try {
    const { truckId } = req.params;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId: req.user.id });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    const accounts = await SocialAccount.find({ truckId, isActive: true });
    
    res.json({ success: true, accounts });
  } catch (error) {
    logger.error('❌ Error fetching social accounts:', error);
    res.status(500).json({ message: 'Error fetching social accounts' });
  }
});

// Disconnect social account
app.delete('/api/social/accounts/:accountId', verifyToken, async (req, res) => {
  try {
    const { accountId } = req.params;
    
    const account = await SocialAccount.findById(accountId);
    if (!account || account.ownerId !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    account.isActive = false;
    await account.save();
    
    logger.info(`🔌 Disconnected ${account.platform} account`);
    res.json({ success: true, message: 'Account disconnected' });
  } catch (error) {
    logger.error('❌ Error disconnecting account:', error);
    res.status(500).json({ message: 'Error disconnecting account' });
  }
});

// Create social media post
app.post('/api/social/posts', verifyToken, async (req, res) => {
  try {
    const { truckId, content, platforms, scheduledTime, isTemplate, templateName, templateCategory, campaignId } = req.body;
    const ownerId = req.user.id;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    const post = new SocialPost({
      truckId,
      ownerId,
      content,
      platforms: platforms.map(p => ({ name: p, status: 'pending' })),
      status: scheduledTime ? 'scheduled' : 'draft',
      scheduledTime: scheduledTime ? new Date(scheduledTime) : null,
      isTemplate,
      templateName,
      templateCategory,
      campaignId
    });
    
    await post.save();
    
    // Add to campaign if specified
    if (campaignId) {
      const campaign = await Campaign.findById(campaignId);
      if (campaign) {
        await campaign.addPost(post._id.toString());
      }
    }
    
    logger.info(`📝 Created social post for truck ${truckId}`);
    res.json({ success: true, post });
  } catch (error) {
    logger.error('❌ Error creating social post:', error);
    res.status(500).json({ message: 'Error creating social post' });
  }
});

// Get social posts
app.get('/api/social/posts/:truckId', verifyToken, async (req, res) => {
  try {
    const { truckId } = req.params;
    const { status, isTemplate, page = 1, limit = 20 } = req.query;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId: req.user.id });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    const query = { truckId };
    if (status) query.status = status;
    if (isTemplate !== undefined) query.isTemplate = isTemplate === 'true';
    
    const posts = await SocialPost.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
      
    const total = await SocialPost.countDocuments(query);
    
    res.json({
      success: true,
      posts,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalItems: total
      }
    });
  } catch (error) {
    logger.error('❌ Error fetching social posts:', error);
    res.status(500).json({ message: 'Error fetching social posts' });
  }
});

// Update social post
app.put('/api/social/posts/:postId', verifyToken, async (req, res) => {
  try {
    const { postId } = req.params;
    const updates = req.body;
    
    const post = await SocialPost.findById(postId);
    if (!post || post.ownerId !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    // Prevent updating published posts
    if (post.status === 'published') {
      return res.status(400).json({ message: 'Cannot edit published posts' });
    }
    
    Object.assign(post, updates);
    await post.save();
    
    logger.info(`✏️ Updated social post ${postId}`);
    res.json({ success: true, post });
  } catch (error) {
    logger.error('❌ Error updating social post:', error);
    res.status(500).json({ message: 'Error updating social post' });
  }
});

// Delete social post
app.delete('/api/social/posts/:postId', verifyToken, async (req, res) => {
  try {
    const { postId } = req.params;
    
    const post = await SocialPost.findById(postId);
    if (!post || post.ownerId !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    if (post.status === 'published') {
      post.status = 'deleted';
      await post.save();
    } else {
      await post.deleteOne();
    }
    
    logger.info(`🗑️ Deleted social post ${postId}`);
    res.json({ success: true, message: 'Post deleted' });
  } catch (error) {
    logger.error('❌ Error deleting social post:', error);
    res.status(500).json({ message: 'Error deleting social post' });
  }
});

// Get content templates
app.get('/api/social/templates/:truckId', verifyToken, async (req, res) => {
  try {
    const { truckId } = req.params;
    const { category } = req.query;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId: req.user.id });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    const templates = await SocialPost.getTemplates(truckId, category);
    
    // Also return default templates if no custom ones exist
    const defaultTemplates = getDefaultTemplates(category);
    
    res.json({
      success: true,
      templates,
      defaultTemplates
    });
  } catch (error) {
    logger.error('❌ Error fetching templates:', error);
    res.status(500).json({ message: 'Error fetching templates' });
  }
});

// Get social media calendar
app.get('/api/social/calendar/:truckId', verifyToken, async (req, res) => {
  try {
    const { truckId } = req.params;
    const { startDate, endDate } = req.query;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId: req.user.id });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    const posts = await SocialPost.getScheduledPosts(
      truckId,
      new Date(startDate),
      new Date(endDate)
    );
    
    res.json({ success: true, posts });
  } catch (error) {
    logger.error('❌ Error fetching calendar:', error);
    res.status(500).json({ message: 'Error fetching calendar' });
  }
});

// Get social analytics
app.get('/api/social/analytics/:truckId', verifyToken, async (req, res) => {
  try {
    const { truckId } = req.params;
    const { startDate, endDate, platform } = req.query;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId: req.user.id });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    const query = {
      truckId,
      status: 'published',
      publishedTime: {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      }
    };
    
    if (platform) {
      query['platforms.name'] = platform;
    }
    
    const posts = await SocialPost.find(query);
    
    // Aggregate analytics
    const analytics = {
      totalPosts: posts.length,
      totalReach: posts.reduce((sum, p) => sum + p.analytics.reach, 0),
      totalEngagement: posts.reduce((sum, p) => sum + p.analytics.engagement, 0),
      totalImpressions: posts.reduce((sum, p) => sum + p.analytics.impressions, 0),
      avgEngagementRate: 0,
      topPosts: posts
        .sort((a, b) => b.analytics.engagement - a.analytics.engagement)
        .slice(0, 5),
      performanceByPlatform: {}
    };
    
    // Calculate average engagement rate
    if (analytics.totalReach > 0) {
      analytics.avgEngagementRate = (analytics.totalEngagement / analytics.totalReach * 100).toFixed(2);
    }
    
    // Group by platform
    const platforms = ['instagram', 'facebook', 'twitter'];
    platforms.forEach(platform => {
      const platformPosts = posts.filter(p => p.platforms.some(pl => pl.name === platform));
      analytics.performanceByPlatform[platform] = {
        posts: platformPosts.length,
        reach: platformPosts.reduce((sum, p) => sum + p.analytics.reach, 0),
        engagement: platformPosts.reduce((sum, p) => sum + p.analytics.engagement, 0)
      };
    });
    
    res.json({ success: true, analytics });
  } catch (error) {
    logger.error('❌ Error fetching analytics:', error);
    res.status(500).json({ message: 'Error fetching analytics' });
  }
});

// Create campaign
app.post('/api/social/campaigns', verifyToken, async (req, res) => {
  try {
    const campaignData = req.body;
    campaignData.ownerId = req.user.id;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: campaignData.truckId, ownerId: req.user.id });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    const campaign = new Campaign(campaignData);
    await campaign.save();
    
    logger.info(`🎯 Created campaign: ${campaign.name}`);
    res.json({ success: true, campaign });
  } catch (error) {
    logger.error('❌ Error creating campaign:', error);
    res.status(500).json({ message: 'Error creating campaign' });
  }
});

// Get campaigns
app.get('/api/social/campaigns/:truckId', verifyToken, async (req, res) => {
  try {
    const { truckId } = req.params;
    const { status } = req.query;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId: req.user.id });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    const query = { truckId };
    if (status) query.status = status;
    
    const campaigns = await Campaign.find(query).sort({ createdAt: -1 });
    
    res.json({ success: true, campaigns });
  } catch (error) {
    logger.error('❌ Error fetching campaigns:', error);
    res.status(500).json({ message: 'Error fetching campaigns' });
  }
});

// Update campaign
app.put('/api/social/campaigns/:campaignId', verifyToken, async (req, res) => {
  try {
    const { campaignId } = req.params;
    
    const campaign = await Campaign.findById(campaignId);
    if (!campaign || campaign.ownerId !== req.user.id) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    Object.assign(campaign, req.body);
    await campaign.save();
    
    logger.info(`✏️ Updated campaign: ${campaign.name}`);
    res.json({ success: true, campaign });
  } catch (error) {
    logger.error('❌ Error updating campaign:', error);
    res.status(500).json({ message: 'Error updating campaign' });
  }
});

// Helper function for default templates
function getDefaultTemplates(category) {
  const templates = {
    'daily-special': [
      {
        name: 'Today\'s Special',
        content: {
          text: '🌟 TODAY\'S SPECIAL 🌟\n\n{special_name}\n{price}\n\n{description}\n\nFind us at: {location}\n\n#foodtruck #dailyspecial #{cuisine}food',
          hashtags: ['foodtruck', 'dailyspecial', 'foodie', 'streetfood']
        }
      }
    ],
    'location-update': [
      {
        name: 'Location Update',
        content: {
          text: '📍 WE\'RE HERE! 📍\n\nCome find us at {location}!\n\nServing until {closing_time}\n\n{menu_highlights}\n\n#foodtruck #{city}eats',
          hashtags: ['foodtruck', 'foodtrucklife', 'streetfood']
        }
      }
    ],
    'new-menu': [
      {
        name: 'New Menu Item',
        content: {
          text: '🎉 NEW ON THE MENU! 🎉\n\nIntroducing {item_name}\n\n{description}\n\nOnly ${price}\n\nCome try it today!\n\n#newmenu #foodtruck',
          hashtags: ['newmenu', 'foodtruck', 'tryit']
        }
      }
    ]
  };
  
  return category ? templates[category] || [] : Object.values(templates).flat();
}

// AI content generation endpoint (mock for now)
app.post('/api/social/generate-content', verifyToken, async (req, res) => {
  try {
    const { truckId, type, context } = req.body;
    
    // Verify user owns the truck
    const truck = await FoodTruck.findOne({ id: truckId, ownerId: req.user.id });
    if (!truck) {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    
    // Mock AI-generated content
    const generatedContent = generateAIContent(truck, type, context);
    
    res.json({ success: true, content: generatedContent });
  } catch (error) {
    logger.error('❌ Error generating content:', error);
    res.status(500).json({ message: 'Error generating content' });
  }
});

// Mock AI content generator
function generateAIContent(truck, type, context) {
  const templates = {
    'engagement': {
      text: `🤔 What's your favorite item from ${truck.name}?\n\nComment below and let us know! The most popular choice might become our special next week! 👇\n\n#${truck.cuisine.toLowerCase()}food #foodtruck #yourchoice`,
      hashtags: ['foodtruck', 'engagement', 'foodie', truck.cuisine.toLowerCase()]
    },
    'promotion': {
      text: `🎊 FLASH SALE ALERT! 🎊\n\nGet 20% off all orders at ${truck.name} today only!\n\nShow this post at checkout to redeem.\n\nFind us at: ${truck.location.address}\n\n#flashsale #discount #foodtruck`,
      hashtags: ['flashsale', 'discount', 'limitedtime', 'foodtruck']
    },
    'menu-highlight': {
      text: `😋 CUSTOMER FAVORITE ALERT! 😋\n\nOur ${context.item || 'signature dish'} has been flying off the truck!\n\n${context.description || 'Made with love and the freshest ingredients.'}\n\nCome taste why everyone's talking about it!\n\n#${truck.cuisine.toLowerCase()} #musttry`,
      hashtags: ['customerfavorite', 'musttry', 'foodtruck', truck.cuisine.toLowerCase()]
    }
  };
  
  return templates[type] || templates['engagement'];
}

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Server error:', err);
  res.status(500).json({ message: 'Something went wrong!' });
});

// 404 handler
app.use(notFound);

// Global error handler (must be last)
app.use(errorHandler);

// Start server
app.listen(PORT, '0.0.0.0', () => {
  logger.info(`🚚 Food Truck API Server running on port ${PORT}`);
  logger.info(`📍 Health check: http://localhost:${PORT}/api/health`);
  logger.info(`💾 Database: MongoDB Atlas (Persistent Storage)`);
  logger.info(`📞 Phone numbers: REMOVED from all user interactions`);
  logger.info(`🎉 Data will now persist between restarts!`);
});

module.exports = app;

const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Import MongoDB models
const User = require('./models/User');
const FoodTruck = require('./models/FoodTruck');
const Favorite = require('./models/Favorite');
const Review = require('./models/Review');

// Import photo upload services
const ImageProcessingService = require('./services/imageProcessingService');
const AutomatedVerificationService = require('./services/automatedVerificationService');

// Initialize services
const automatedVerification = new AutomatedVerificationService();

// Phase 3: Advanced Caching System
const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
const requestMetrics = {
  totalRequests: 0,
  cachedResponses: 0,
  avgResponseTime: 0,
  slowQueries: []
};

// Phase 3: Performance Monitoring Middleware
const performanceMonitor = (req, res, next) => {
  const startTime = Date.now();
  requestMetrics.totalRequests++;
  
  res.on('finish', () => {
    const responseTime = Date.now() - startTime;
    requestMetrics.avgResponseTime = 
      (requestMetrics.avgResponseTime * (requestMetrics.totalRequests - 1) + responseTime) / 
      requestMetrics.totalRequests;
    
    if (responseTime > 1000) { // Log slow queries (>1s)
      requestMetrics.slowQueries.push({
        path: req.path,
        method: req.method,
        responseTime,
        timestamp: new Date()
      });
      
      // Keep only last 50 slow queries
      if (requestMetrics.slowQueries.length > 50) {
        requestMetrics.slowQueries = requestMetrics.slowQueries.slice(-50);
      }
    }
  });
  
  next();
};

// Phase 3: Cache Helper Functions
const getCacheKey = (prefix, ...params) => `${prefix}:${params.join(':')}`;

const setCache = (key, data, ttl = CACHE_TTL) => {
  cache.set(key, {
    data,
    expiry: Date.now() + ttl
  });
};

const getCache = (key) => {
  const cached = cache.get(key);
  if (!cached) return null;
  
  if (Date.now() > cached.expiry) {
    cache.delete(key);
    return null;
  }
  
  requestMetrics.cachedResponses++;
  return cached.data;
};

// Async error handler
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Phase 3: Security and Performance Middleware
app.use(helmet());
app.use(compression());
app.use(performanceMonitor);
app.use(morgan('combined'));

// Phase 3: Rate Limiting with Render/proxy support
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  // Fix for Render proxy environment
  trustProxy: true,
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/api/health' || req.path === '/';
  }
});
app.use('/api/', limiter);

// Middleware - Configure CORS for development (allow all origins)
app.use(cors({
  origin: true, // Allow all origins for development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(express.json());

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://codycook:sLYlcz4fvFDVGKxk@cluster0.bpjvh.mongodb.net/foodtruckapp?retryWrites=true&w=majority';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas successfully!');
    initializeDefaultData();
  })
  .catch((error) => {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  });

// Helper function to check if a truck is currently open with timezone support
function isCurrentlyOpen(schedule, timezone = 'America/Denver') {
  if (!schedule) return false;
  
  try {
    // Get current time in the truck's timezone
    const now = new Date();
    const localTime = new Intl.DateTimeFormat('en-US', {
      timeZone: timezone,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
      weekday: 'long'
    }).formatToParts(now);
    
    const dayMap = {
      'Monday': 'monday',
      'Tuesday': 'tuesday', 
      'Wednesday': 'wednesday',
      'Thursday': 'thursday',
      'Friday': 'friday',
      'Saturday': 'saturday',
      'Sunday': 'sunday'
    };
    
    const currentDay = dayMap[localTime.find(part => part.type === 'weekday').value];
    const currentTime = `${localTime.find(part => part.type === 'hour').value}:${localTime.find(part => part.type === 'minute').value}`;
    
    console.log(`🕐 Time check for ${timezone}: ${currentDay} ${currentTime}`);
    
    const todaySchedule = schedule[currentDay];
    if (!todaySchedule || !todaySchedule.isOpen) {
      return false;
    }
    
    const isOpen = currentTime >= todaySchedule.open && currentTime <= todaySchedule.close;
    console.log(`🚚 Schedule: ${todaySchedule.open}-${todaySchedule.close}, Current: ${currentTime}, Open: ${isOpen}`);
    
    return isOpen;
  } catch (error) {
    console.error('❌ Timezone error, falling back to UTC:', error);
    // Fallback to original UTC logic
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
}

// Phase 2: Helper function to calculate distance between two points
function calculateDistance(lat1, lon1, lat2, lon2) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return 999999; // Large number for invalid coordinates
  
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c;
  
  return Math.round(distance * 100) / 100; // Round to 2 decimal places
}

// Initialize database with default data if empty
async function initializeDefaultData() {
  try {
    // Check if we already have data
    const userCount = await User.countDocuments();
    const truckCount = await FoodTruck.countDocuments();
    
    if (userCount === 0) {
      console.log('📝 Initializing default users...');
      const defaultUsers = [
        {
          name: 'John Customer',
          email: 'john@customer.com',
          password: 'password123',
          role: 'customer',
          createdAt: new Date()
        },
        {
          name: 'Mike Rodriguez',
          email: 'mike@tacos.com',
          password: 'password123',
          role: 'owner',
          businessName: 'Mike\'s Tacos',
          createdAt: new Date()
        }
      ];
      
      // Performance monitoring middleware
app.use((req, res, next) => {
  req.startTime = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - req.startTime;
    if (duration > 1000) {
      console.warn(`🐌 Slow request: ${req.method} ${req.path} took ${duration}ms`);
    }
    if (duration > 5000) {
      console.error(`🚨 Very slow request: ${req.method} ${req.path} took ${duration}ms`);
    }
  });
  next();
});

// Cache helper functions
const getCacheKey = (prefix, params) => `${prefix}:${JSON.stringify(params)}`;
const getFromCache = (key) => {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data;
  }
  cache.delete(key);
  return null;
};
const setCache = (key, data) => {
  cache.set(key, { data, timestamp: Date.now() });
  // Clean old cache entries
  if (cache.size > 1000) {
    const keys = [...cache.keys()];
    keys.slice(0, 100).forEach(k => cache.delete(k));
  }
};

      await User.insertMany(defaultUsers);
      console.log('✅ Default users created');
    }

    if (truckCount === 0) {
      console.log('📝 Initializing default food trucks...');
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
          ownerId: 'owner1',
          schedule: {
            monday: { open: '11:00', close: '21:00', isOpen: true },
            tuesday: { open: '11:00', close: '21:00', isOpen: true },
            wednesday: { open: '11:00', close: '21:00', isOpen: true },
            thursday: { open: '11:00', close: '21:00', isOpen: true },
            friday: { open: '11:00', close: '21:00', isOpen: true },
            saturday: { open: '11:00', close: '21:00', isOpen: true },
            sunday: { open: '12:00', close: '20:00', isOpen: true }
          }
        }
      ];
      
      await FoodTruck.insertMany(defaultTrucks);
      console.log('✅ Default food trucks created');
    }

    console.log('🎉 Database initialization complete!');
  } catch (error) {
    console.error('❌ Error initializing default data:', error);
  }
}

// Root route
app.get('/', (req, res) => {
  res.json({
    message: '🚚 Food Truck API Server is running!',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth/*',
      trucks: '/api/trucks',
      favorites: '/api/users/:userId/favorites'
    }
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// ===== FLEXIBLE USER LOOKUP FUNCTION =====
async function findUserFlexibly(identifier) {
  console.log(`🔍 Looking for user with identifier: ${identifier}`);
  
  let user = null;
  
  // Try different lookup methods
  try {
    // 1. Try as MongoDB ObjectId
    if (mongoose.Types.ObjectId.isValid(identifier)) {
      user = await User.findById(identifier);
      if (user) {
        console.log(`✅ Found user by ObjectId: ${user._id}`);
        return user;
      }
    }
    
    // 2. Try as userId field
    user = await User.findOne({ userId: identifier });
    if (user) {
      console.log(`✅ Found user by userId field: ${user._id}`);
      return user;
    }
    
    // 3. Try as email
    user = await User.findOne({ email: identifier });
    if (user) {
      console.log(`✅ Found user by email: ${user._id}`);
      return user;
    }
    
    // 4. Try as custom string ID (legacy)
    user = await User.findOne({ _id: identifier });
    if (user) {
      console.log(`✅ Found user by custom _id: ${user._id}`);
      return user;
    }
    
    console.log(`❌ No user found with identifier: ${identifier}`);
    return null;
    
  } catch (error) {
    console.error(`❌ Error in flexible user lookup:`, error);
    return null;
  }
}

// ===== AUTHENTICATION ROUTES =====

// Register endpoint - FIXED to use MongoDB ObjectIds consistently
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password, role, businessName } = req.body;
    
    console.log(`📝 Registration attempt: ${email} as ${role}`);
    
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log(`❌ Registration failed: Email ${email} already exists`);
      return res.status(400).json({ success: false, message: 'Email already exists' });
    }
    
    // For food truck owners, check if they have submitted and approved verification
    if (role === 'owner') {
      const verificationUser = await User.findOne({ email });
      if (!verificationUser || 
          !verificationUser.businessVerification ||
          verificationUser.businessVerification.verificationStatus !== 'approved') {
        return res.status(400).json({ 
          success: false, 
          message: 'Business verification required. Please complete the verification process before registering as a food truck owner.',
          requiresVerification: true
        });
      }
    }
    
    // Create new user - LET MONGODB GENERATE THE _id, then use it consistently
    const newUser = new User({
      // DON'T set _id manually, let MongoDB generate it
      name,
      email,
      password,
      role,
      businessName,
      createdAt: new Date()
    });
    
    // Save user first to get the MongoDB-generated _id
    const savedUser = await newUser.save();
    
    // NOW set userId to match _id for consistency
    savedUser.userId = savedUser._id.toString();
    await savedUser.save();
    
    console.log(`✅ User created successfully: ${email}`);
    console.log(`🆔 User ID: ${savedUser._id}`);
    console.log(`🆔 User userId field: ${savedUser.userId}`);
    
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
          monday: { open: '09:00', close: '17:00', isOpen: true },
          tuesday: { open: '09:00', close: '17:00', isOpen: true },
          wednesday: { open: '09:00', close: '17:00', isOpen: true },
          thursday: { open: '09:00', close: '17:00', isOpen: true },
          friday: { open: '09:00', close: '17:00', isOpen: true },
          saturday: { open: '10:00', close: '16:00', isOpen: true },
          sunday: { open: '10:00', close: '16:00', isOpen: false }
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
      console.log(`🚚 Auto-created food truck for owner: ${businessName} (ID: ${foodTruckId})`);
    }
    
    // CONSISTENT TOKEN: Always use MongoDB _id
    const token = `token_${savedUser._id}_${Date.now()}`;
    
    // CONSISTENT RESPONSE: Always return _id as the main identifier
    res.json({
      success: true,
      token: token,
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
    console.error('❌ Registration error:', error);
    res.status(500).json({ success: false, message: 'Server error during registration' });
  }
});

// Login endpoint - FIXED to use MongoDB ObjectIds consistently
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    console.log(`🔐 Login attempt: ${email}`);
    
    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      console.log(`❌ Login failed: User ${email} not found`);
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Simple password check (in production, use bcrypt)
    if (user.password !== password) {
      console.log(`❌ Login failed: Invalid password for ${email}`);
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Update userId field if it doesn't match _id (migration fix)
    if (user.userId !== user._id.toString()) {
      user.userId = user._id.toString();
      await user.save();
      console.log(`🔧 Updated userId field for user: ${user._id}`);
    }
    
    // Find associated food truck for owners
    let foodTruckId = null;
    if (user.role === 'owner') {
      const truck = await FoodTruck.findOne({ ownerId: user._id.toString() });
      if (truck) {
        foodTruckId = truck.id;
      }
    }
    
    console.log(`✅ Login successful: ${email}`);
    console.log(`🆔 User ID: ${user._id}`);
    
    // CONSISTENT TOKEN: Always use MongoDB _id
    const token = `token_${user._id}_${Date.now()}`;
    
    // CONSISTENT RESPONSE: Always return _id as the main identifier
    res.json({
      success: true,
      token: token,
      user: {
        _id: user._id.toString(),        // MongoDB _id
        id: user._id.toString(),         // Same as _id for mobile app compatibility
        userId: user._id.toString(),     // Same as _id for legacy compatibility
        name: user.name,
        email: user.email,
        role: user.role,
        businessName: user.businessName,
        foodTruckId: foodTruckId
      }
    });
    
  } catch (error) {
    console.error('❌ Login error:', error);
    res.status(500).json({ success: false, message: 'Server error during login' });
  }
});

// Forgot password endpoint
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    
    console.log(`🔑 Forgot password request: ${email}`);
    
    const user = await findUserFlexibly(email);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // In a real app, you would send an email with a reset token
    // For now, just return success
    console.log(`✅ Password reset requested for: ${user.email}`);
    
    res.json({
      success: true,
      message: 'Password reset instructions sent to your email'
    });
    
  } catch (error) {
    console.error('❌ Forgot password error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ===== BUSINESS VERIFICATION ROUTES =====

// Submit business verification
app.post('/api/auth/business-verification', async (req, res) => {
  try {
    const { 
      email,
      businessName,
      businessLicenseNumber,
      foodServicePermit,
      businessType,
      yearsInBusiness,
      businessState,
      businessPhone,
      businessEmail,
      ein // Add EIN field for automated verification
    } = req.body;
    
    console.log(`🏢 Business verification submission: ${email}`);
    
    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // 🤖 STEP 1: Attempt Automated Verification First
    console.log(`🤖 Starting automated verification for: ${businessName}`);
    
    const automatedResult = await automatedVerification.verifyBusiness({
      businessName,
      businessLicenseNumber,
      foodServicePermit,
      businessState,
      ein,
      businessPhone,
      businessEmail
    });

    let finalStatus = 'pending';
    let isAutoVerified = false;
    let verificationMessage = 'Business verification submitted successfully. Review typically takes 1-2 business days.';

    // 🎯 STEP 2: Determine Final Status Based on Automated Results
    if (automatedResult.overall.verified && automatedResult.automatedScore >= 80) {
      // ✅ FULLY AUTOMATED APPROVAL
      finalStatus = 'approved';
      isAutoVerified = true;
      verificationMessage = `🎉 Business automatically verified! (Confidence: ${automatedResult.automatedScore}%) You can now register your food truck.`;
      console.log(`✅ AUTOMATED APPROVAL for ${businessName} (Score: ${automatedResult.automatedScore}%)`);
      
    } else if (automatedResult.requiresManualReview) {
      // ⚠️ FALLBACK TO MANUAL REVIEW
      finalStatus = 'pending_manual_review';
      verificationMessage = `Automated verification incomplete (Score: ${automatedResult.automatedScore}%). Your application will be manually reviewed within 1-2 business days.`;
      console.log(`⚠️ MANUAL REVIEW REQUIRED for ${businessName} (Score: ${automatedResult.automatedScore}%)`);
    }

    // 📝 STEP 3: Update User Record with All Verification Data
    user.businessVerification = {
      isVerified: isAutoVerified,
      verificationStatus: finalStatus,
      businessLicenseNumber,
      foodServicePermit,
      businessType,
      yearsInBusiness,
      businessState,
      businessPhone,
      businessEmail,
      ein,
      submittedAt: new Date(),
      
      // 🤖 Automated Verification Results
      automatedVerification: {
        attempted: true,
        score: automatedResult.automatedScore,
        confidence: automatedResult.overall.confidence,
        checks: automatedResult.checks,
        autoApproved: isAutoVerified,
        requiresManualReview: automatedResult.requiresManualReview,
        completedAt: new Date()
      }
    };

    // If auto-approved, set approval timestamp
    if (isAutoVerified) {
      user.businessVerification.reviewedAt = new Date();
      user.businessVerification.reviewedBy = 'automated_system';
      user.businessVerification.approvalMethod = 'automated';
    }
    
    // Update business name if provided
    if (businessName) {
      user.businessName = businessName;
    }
    
    await user.save();
    
    console.log(`✅ Business verification processed for: ${email} (Status: ${finalStatus})`);
    
    res.json({
      success: true,
      message: verificationMessage,
      verificationStatus: finalStatus,
      isAutoVerified: isAutoVerified,
      automatedScore: automatedResult.automatedScore,
      confidence: automatedResult.overall.confidence,
      requiresManualReview: automatedResult.requiresManualReview
    });
    
  } catch (error) {
    console.error('❌ Business verification error:', error);
    res.status(500).json({ success: false, message: 'Server error during verification submission' });
  }
});

// Check verification status
app.get('/api/auth/verification-status/:email', async (req, res) => {
  try {
    const { email } = req.params;
    
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    res.json({
      success: true,
      verificationStatus: user.businessVerification?.verificationStatus || 'not_submitted',
      isVerified: user.businessVerification?.isVerified || false,
      submittedAt: user.businessVerification?.submittedAt,
      rejectionReason: user.businessVerification?.rejectionReason
    });
    
  } catch (error) {
    console.error('❌ Verification status check error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Admin endpoint to approve/reject verification (for future use)
app.put('/api/admin/business-verification/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { action, rejectionReason } = req.body; // action: 'approve' or 'reject'
    
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    if (action === 'approve') {
      user.businessVerification.isVerified = true;
      user.businessVerification.verificationStatus = 'approved';
      user.businessVerification.reviewedAt = new Date();
    } else if (action === 'reject') {
      user.businessVerification.isVerified = false;
      user.businessVerification.verificationStatus = 'rejected';
      user.businessVerification.rejectionReason = rejectionReason;
      user.businessVerification.reviewedAt = new Date();
    }
    
    await user.save();
    
    res.json({
      success: true,
      message: `Business verification ${action}d successfully`
    });
    
  } catch (error) {
    console.error('❌ Admin verification action error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ===== USER MANAGEMENT ROUTES =====

// Change email endpoint
app.put('/api/users/:userId/email', async (req, res) => {
  try {
    const { userId } = req.params;
    const { newEmail } = req.body;
    
    console.log(`📧 Email change request for user: ${userId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Check if new email already exists
    const existingUser = await User.findOne({ email: newEmail });
    if (existingUser && existingUser._id.toString() !== user._id.toString()) {
      return res.status(400).json({ success: false, message: 'Email already in use' });
    }
    
    user.email = newEmail;
    await user.save();
    
    console.log(`✅ Email updated for user: ${user._id}`);
    
    res.json({
      success: true,
      message: 'Email updated successfully',
      user: {
        _id: user._id.toString(),
        id: user._id.toString(),
        userId: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        businessName: user.businessName
      }
    });
    
  } catch (error) {
    console.error('❌ Change email error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Change password endpoint
app.put('/api/users/:userId/password', async (req, res) => {
  try {
    const { userId } = req.params;
    const { currentPassword, newPassword } = req.body;
    
    console.log(`🔐 Password change request for user: ${userId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Verify current password
    if (user.password !== currentPassword) {
      return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    }
    
    user.password = newPassword;
    await user.save();
    
    console.log(`✅ Password updated for user: ${user._id}`);
    
    res.json({
      success: true,
      message: 'Password updated successfully'
    });
    
  } catch (error) {
    console.error('❌ Change password error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ===== FOOD TRUCK ROUTES =====

// Get all food trucks - Phase 3 Optimized with Caching
app.get('/api/trucks', asyncHandler(async (req, res) => {
  const cacheKey = getCacheKey('all-trucks');
  const cached = getCache(cacheKey);
  
  if (cached) {
    console.log('📋 Returning cached trucks list');
    return res.json(cached);
  }
  
  const trucks = await FoodTruck.find({ isActive: true }).lean(); // Use lean() for better performance
  
  // Update open/closed status for all trucks based on current time
  const updatedTrucks = trucks.map(truck => ({
    ...truck,
    isOpen: isCurrentlyOpen(truck.schedule, truck.timezone)
  }));
  
  console.log(`📋 Getting all trucks: ${trucks.length} available`);
  
  // Cache for shorter time since status changes frequently
  setCache(cacheKey, updatedTrucks, 2 * 60 * 1000); // 2 minutes cache
  
  res.json(updatedTrucks);
}));

// Get single food truck
app.get('/api/trucks/:id', async (req, res) => {
  try {
    const truck = await FoodTruck.findOne({ id: req.params.id });
    if (truck) {
      console.log(`🚚 Found truck: ${truck.name}`);
      // Update open/closed status based on current time
      const updatedTruck = {
        ...truck.toObject(),
        isOpen: isCurrentlyOpen(truck.schedule, truck.timezone)
      };
      res.json(updatedTruck);
    } else {
      console.log(`❌ Truck ${req.params.id} not found`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error fetching truck:', error);
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
    console.error('❌ Error fetching menu:', error);
    res.status(500).json({ message: 'Error fetching menu' });
  }
});

// Update truck location
app.put('/api/trucks/:id/location', async (req, res) => {
  try {
    const { id } = req.params;
    const { latitude, longitude, address } = req.body;
    
    console.log(`📍 Location update request for truck ${id}`);
    console.log(`📍 New location: ${latitude}, ${longitude} - ${address}`);
    
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
      console.log(`✅ Location updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Location updated successfully',
        location: truck.location 
      });
    } else {
      console.log(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating location:', error);
    res.status(500).json({ message: 'Error updating location' });
  }
});

// Update cover photo - MongoDB-only storage (simplified)
app.put('/api/trucks/:id/cover-photo', async (req, res) => {
  try {
    const { id } = req.params;
    let imageUrl = null;
    
    console.log(`📸 Cover photo update request for truck ${id}`);
    
    // Handle base64 image data (our preferred method)
    if (req.body.base64Image) {
      const base64Data = req.body.base64Image;
      console.log(`📱 Base64 image provided, size: ${base64Data.length} characters`);
      
      // Check if base64 is reasonable size (max ~3.5MB when encoded = ~2.5MB original)
      // This is well within MongoDB's 16MB document limit
      if (base64Data.length > 4700000) {
        return res.status(400).json({ 
          message: 'Image too large. Please use a smaller image (max 2.5MB).' 
        });
      }
      
      // Validate base64 format
      if (!base64Data.startsWith('data:image/')) {
        return res.status(400).json({ 
          message: 'Invalid image format. Please provide a valid image.' 
        });
      }
      
      imageUrl = base64Data;
      console.log(`✅ Base64 image accepted for MongoDB storage`);
    }
    // Handle legacy URL uploads (from existing data)
    else if (req.body.imageUrl) {
      imageUrl = req.body.imageUrl;
      console.log(`🔗 Image URL provided: ${imageUrl.substring(0, 50)}...`);
    }
    
    if (!imageUrl) {
      return res.status(400).json({ 
        message: 'No image provided. Please provide a base64 image or image URL.' 
      });
    }
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        coverImage: imageUrl,  // Use coverImage field instead of image
        image: imageUrl,       // Also update image for backward compatibility
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      console.log(`✅ Cover photo updated for ${truck.name}`);
      
      // Invalidate cache to ensure updated photos are immediately visible
      cache.delete(getCacheKey('all-trucks'));
      cache.delete(getCacheKey('truck', id));
      console.log(`🗑️ Cache invalidated for truck ${id}`);
      
      res.json({ 
        success: true, 
        message: 'Cover photo updated successfully',
        image: truck.coverImage,  // Return coverImage
        coverImage: truck.coverImage,  // Ensure both fields are available
        storageType: 'mongodb'
      });
    } else {
      console.log(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating cover photo:', error);
    
    // If there was an upload error, provide more specific error message
    if (error.message.includes('Only image files are allowed')) {
      return res.status(400).json({ 
        message: 'Invalid file type. Please upload an image file (JPG, PNG, or WebP).' 
      });
    }
    
    if (error.message.includes('File too large')) {
      return res.status(400).json({ 
        message: 'File too large. Please upload an image smaller than 5MB.' 
      });
    }
    
    res.status(500).json({ 
      message: 'Error updating cover photo',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Delete food truck
app.delete('/api/trucks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`🗑️ Delete request for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndDelete({ id });
    
    if (truck) {
      console.log(`✅ Deleted truck: ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Food truck deleted successfully'
      });
    } else {
      console.log(`❌ Truck not found: ${id}`);
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error deleting truck:', error);
    res.status(500).json({ message: 'Error deleting food truck' });
  }
});

// Search food trucks
app.get('/api/trucks/search', async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q) {
      return res.status(400).json({ message: 'Search query is required' });
    }
    
    console.log(`🔍 Searching trucks for: ${q}`);
    
    const trucks = await FoodTruck.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { cuisine: { $regex: q, $options: 'i' } }
      ]
    });
    
    const updatedTrucks = trucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule, truck.timezone)
    }));
    
    console.log(`✅ Found ${trucks.length} trucks matching: ${q}`);
    res.json(updatedTrucks);
  } catch (error) {
    console.error('❌ Error searching trucks:', error);
    res.status(500).json({ message: 'Error searching food trucks' });
  }
});

// Get nearby trucks - Phase 2 & 3 Optimized
app.get('/api/trucks/nearby', asyncHandler(async (req, res) => {
  const { lat, lng, radius = 10 } = req.query;
  
  if (!lat || !lng) {
    return res.status(400).json({ message: 'Latitude and longitude are required' });
  }
  
  const cacheKey = getCacheKey('nearby', lat, lng, radius);
  const cached = getCache(cacheKey);
  
  if (cached) {
    console.log(`📍 Returning cached nearby trucks for: ${lat}, ${lng}`);
    return res.json(cached);
  }
  
  console.log(`📍 Finding trucks near: ${lat}, ${lng} within ${radius}km`);
  
  // Phase 2: Use MongoDB's geospatial queries for better performance
  const longitude = parseFloat(lng);
  const latitude = parseFloat(lat);
  const radiusInMeters = parseFloat(radius) * 1000;
  
  try {
    // First try using GeoJSON coordinates (new method)
    let nearbyTrucks = await FoodTruck.find({
      'location.coordinates': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude]
          },
          $maxDistance: radiusInMeters
        }
      },
      isActive: true
    }).limit(50); // Performance limit
    
    // Fallback to manual calculation if no coordinates or no results
    if (nearbyTrucks.length === 0) {
      console.log('📍 Falling back to manual distance calculation');
      const allTrucks = await FoodTruck.find({ 
        isActive: true,
        'location.latitude': { $exists: true },
        'location.longitude': { $exists: true }
      });
      
      nearbyTrucks = allTrucks.filter(truck => {
        const R = 6371; // Earth's radius in km
        const dLat = (latitude - truck.location.latitude) * Math.PI / 180;
        const dLng = (longitude - truck.location.longitude) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                  Math.cos(truck.location.latitude * Math.PI / 180) * 
                  Math.cos(latitude * Math.PI / 180) *
                  Math.sin(dLng/2) * Math.sin(dLng/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const distance = R * c;
        
        return distance <= parseFloat(radius);
      });
    }
    
    // Add live status and calculate actual distance
    const enrichedTrucks = nearbyTrucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule, truck.timezone),
      distance: calculateDistance(latitude, longitude, truck.location.latitude, truck.location.longitude)
    })).sort((a, b) => a.distance - b.distance);
    
    console.log(`✅ Found ${enrichedTrucks.length} nearby trucks`);
    
    // Phase 3: Cache the results
    setCache(cacheKey, enrichedTrucks, CACHE_TTL);
    
    res.json(enrichedTrucks);
    
  } catch (error) {
    console.error('❌ Error finding nearby trucks:', error);
    res.status(500).json({ message: 'Error finding nearby trucks' });
  }
}));

// ===== SCHEDULE MANAGEMENT ROUTES =====

// Get truck schedule
app.get('/api/trucks/:id/schedule', async (req, res) => {
  try {
    const { id } = req.params;
    const truck = await FoodTruck.findOne({ id });
    
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    res.json({
      success: true,
      schedule: truck.schedule,
      isCurrentlyOpen: isCurrentlyOpen(truck.schedule, truck.timezone)
    });
  } catch (error) {
    console.error('❌ Error fetching schedule:', error);
    res.status(500).json({ message: 'Error fetching schedule' });
  }
});

// Update truck schedule
app.put('/api/trucks/:id/schedule', async (req, res) => {
  try {
    const { id } = req.params;
    const { schedule } = req.body;
    
    console.log(`📅 Schedule update request for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        schedule,
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      console.log(`✅ Schedule updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Schedule updated successfully',
        schedule: truck.schedule,
        isCurrentlyOpen: isCurrentlyOpen(truck.schedule, truck.timezone)
      });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating schedule:', error);
    res.status(500).json({ message: 'Error updating schedule' });
  }
});

// Update all truck schedules (batch operation)
app.post('/api/trucks/update-schedules', async (req, res) => {
  try {
    console.log('🔄 Updating all truck open/closed status...');
    
    const trucks = await FoodTruck.find();
    let updatedCount = 0;
    
    for (const truck of trucks) {
      const wasOpen = truck.isOpen;
      const shouldBeOpen = isCurrentlyOpen(truck.schedule, truck.timezone);
      
      if (wasOpen !== shouldBeOpen) {
        await FoodTruck.findOneAndUpdate(
          { id: truck.id },
          { isOpen: shouldBeOpen, lastUpdated: new Date() }
        );
        updatedCount++;
        console.log(`📅 ${truck.name}: ${wasOpen ? 'OPEN' : 'CLOSED'} → ${shouldBeOpen ? 'OPEN' : 'CLOSED'}`);
      }
    }
    
    console.log(`✅ Schedule update complete: ${updatedCount} trucks updated`);
    res.json({
      success: true,
      message: `Updated ${updatedCount} truck schedules`,
      updatedCount
    });
  } catch (error) {
    console.error('❌ Error updating schedules:', error);
    res.status(500).json({ message: 'Error updating schedules' });
  }
});

// ===== MENU MANAGEMENT ROUTES =====

// Update truck menu
app.put('/api/trucks/:id/menu', async (req, res) => {
  try {
    const { id } = req.params;
    const { menu } = req.body;
    
    console.log(`🍽️ Menu update request for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        menu,
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (truck) {
      console.log(`✅ Menu updated for ${truck.name}`);
      res.json({ 
        success: true, 
        message: 'Menu updated successfully',
        menu: truck.menu 
      });
    } else {
      res.status(404).json({ message: 'Food truck not found' });
    }
  } catch (error) {
    console.error('❌ Error updating menu:', error);
    res.status(500).json({ message: 'Error updating menu' });
  }
});

// ===== FAVORITES ROUTES =====

// Get user favorites
app.get('/api/users/:userId/favorites', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`❤️ Getting favorites for user: ${userId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const favorites = await Favorite.find({ userId: user._id.toString() });
    const truckIds = favorites.map(fav => fav.truckId);
    
    const trucks = await FoodTruck.find({ id: { $in: truckIds } });
    const updatedTrucks = trucks.map(truck => ({
      ...truck.toObject(),
      isOpen: isCurrentlyOpen(truck.schedule, truck.timezone)
    }));
    
    console.log(`✅ Found ${trucks.length} favorite trucks for user: ${user._id}`);
    res.json({ success: true, favorites: updatedTrucks });
  } catch (error) {
    console.error('❌ Error fetching favorites:', error);
    res.status(500).json({ success: false, message: 'Error fetching favorites' });
  }
});

// Add favorite
app.post('/api/users/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    console.log(`❤️ Adding favorite: User ${userId} → Truck ${truckId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const truck = await FoodTruck.findOne({ id: truckId });
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found' });
    }
    
    // Check if already favorited
    const existingFavorite = await Favorite.findOne({ 
      userId: user._id.toString(), 
      truckId 
    });
    
    if (existingFavorite) {
      return res.status(400).json({ success: false, message: 'Already in favorites' });
    }
    
    const favorite = new Favorite({
      userId: user._id.toString(),
      truckId,
      createdAt: new Date()
    });
    
    await favorite.save();
    
    console.log(`✅ Added favorite: ${user._id} → ${truckId}`);
    res.json({ success: true, message: 'Added to favorites' });
  } catch (error) {
    console.error('❌ Error adding favorite:', error);
    res.status(500).json({ success: false, message: 'Error adding favorite' });
  }
});

// Remove favorite
app.delete('/api/users/:userId/favorites/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    console.log(`💔 Removing favorite: User ${userId} → Truck ${truckId}`);
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const result = await Favorite.findOneAndDelete({ 
      userId: user._id.toString(), 
      truckId 
    });
    
    if (result) {
      console.log(`✅ Removed favorite: ${user._id} → ${truckId}`);
      res.json({ success: true, message: 'Removed from favorites' });
    } else {
      res.status(404).json({ success: false, message: 'Favorite not found' });
    }
  } catch (error) {
    console.error('❌ Error removing favorite:', error);
    res.status(500).json({ success: false, message: 'Error removing favorite' });
  }
});

// Check if truck is favorited
app.get('/api/users/:userId/favorites/check/:truckId', async (req, res) => {
  try {
    const { userId, truckId } = req.params;
    
    const user = await findUserFlexibly(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const favorite = await Favorite.findOne({ 
      userId: user._id.toString(), 
      truckId 
    });
    
    res.json({ 
      success: true, 
      isFavorite: !!favorite 
    });
  } catch (error) {
    console.error('❌ Error checking favorite:', error);
    res.status(500).json({ success: false, message: 'Error checking favorite' });
  }
});

// ===== ANALYTICS ROUTES =====

// Get truck analytics
app.get('/api/trucks/:id/analytics', async (req, res) => {
  try {
    const { id } = req.params;
    
    const truck = await FoodTruck.findOne({ id });
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    // Get favorite count
    const favoriteCount = await Favorite.countDocuments({ truckId: id });
    
    // Mock analytics data (in a real app, you'd track these metrics)
    const analytics = {
      totalViews: Math.floor(Math.random() * 1000) + 100,
      totalFavorites: favoriteCount,
      averageRating: truck.rating || 0,
      totalReviews: truck.reviewCount || 0,
      weeklyViews: Array.from({ length: 7 }, () => Math.floor(Math.random() * 50) + 10),
      popularItems: truck.menu.slice(0, 3).map(item => ({
        name: item.name,
        orders: Math.floor(Math.random() * 100) + 10
      }))
    };
    
    res.json({ success: true, analytics });
  } catch (error) {
    console.error('❌ Error fetching analytics:', error);
    res.status(500).json({ message: 'Error fetching analytics' });
  }
});

// Phase 3: Performance Monitoring Endpoints
app.get('/api/performance/metrics', (req, res) => {
  const cacheHitRate = requestMetrics.totalRequests > 0 ? 
    (requestMetrics.cachedResponses / requestMetrics.totalRequests * 100).toFixed(2) : 0;
  
  res.json({
    performance: {
      totalRequests: requestMetrics.totalRequests,
      cachedResponses: requestMetrics.cachedResponses,
      cacheHitRate: `${cacheHitRate}%`,
      avgResponseTime: `${Math.round(requestMetrics.avgResponseTime)}ms`,
      slowQueries: requestMetrics.slowQueries.slice(-10), // Last 10 slow queries
      cacheSize: cache.size,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage()
    }
  });
});

app.get('/api/performance/cache/clear', (req, res) => {
  cache.clear();
  res.json({ message: 'Cache cleared successfully', cacheSize: cache.size });
});

// Health check endpoint with enhanced info
app.get('/api/health', async (req, res) => {
  try {
    // Check database connection
    const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
    const truckCount = await FoodTruck.countDocuments();
    const userCount = await User.countDocuments();
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: {
        status: dbStatus,
        collections: {
          foodTrucks: truckCount,
          users: userCount
        }
      },
      performance: {
        uptime: process.uptime(),
        requests: requestMetrics.totalRequests,
        cacheHitRate: requestMetrics.totalRequests > 0 ? 
          `${(requestMetrics.cachedResponses / requestMetrics.totalRequests * 100).toFixed(2)}%` : '0%'
      }
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'unhealthy', 
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ===== POS INTEGRATION ROUTES =====

// Get POS settings for owner
app.get('/api/pos/settings/:ownerId', async (req, res) => {
  try {
    const { ownerId } = req.params;
    
    console.log(`🏪 Getting POS settings for owner: ${ownerId}`);
    
    const truck = await FoodTruck.findOne({ ownerId });
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found for this owner' });
    }
    
    // Return POS settings with defaults if not set
    const posSettings = truck.posSettings || {
      parentAccountId: ownerId,
      childAccounts: [],
      allowPosTracking: true,
      posApiKey: `pos_${ownerId}_${Date.now()}`,
      posWebhookUrl: null
    };
    
    res.json({
      success: true,
      ...posSettings
    });
    
  } catch (error) {
    console.error('❌ Error fetching POS settings:', error);
    res.status(500).json({ success: false, message: 'Error fetching POS settings' });
  }
});

// Update POS settings
app.put('/api/pos/settings/:ownerId', async (req, res) => {
  try {
    const { ownerId } = req.params;
    const { allowPosTracking, posWebhookUrl } = req.body;
    
    console.log(`🏪 Updating POS settings for owner: ${ownerId}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { ownerId },
      { 
        'posSettings.allowPosTracking': allowPosTracking,
        'posSettings.posWebhookUrl': posWebhookUrl,
        lastUpdated: new Date()
      },
      { new: true }
    );
    
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found for this owner' });
    }
    
    console.log(`✅ POS settings updated for owner: ${ownerId}`);
    
    res.json({
      success: true,
      message: 'POS settings updated successfully',
      posSettings: truck.posSettings
    });
    
  } catch (error) {
    console.error('❌ Error updating POS settings:', error);
    res.status(500).json({ success: false, message: 'Error updating POS settings' });
  }
});

// Get POS settings by truck ID (for mobile app compatibility)
app.get('/api/trucks/:id/pos-settings', async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`🏪 Getting POS settings for truck ID: ${id}`);
    
    // Use custom 'id' field instead of MongoDB's '_id'
    const truck = await FoodTruck.findOne({ id: id });
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found' });
    }
    
    // Return POS settings with defaults if not set
    const posSettings = truck.posSettings || {
      parentAccountId: truck.ownerId,
      childAccounts: [],
      allowPosTracking: true,
      posApiKey: `pos_${truck.ownerId}_${Date.now()}`,
      posWebhookUrl: null
    };
    
    console.log(`✅ POS settings retrieved for truck: ${truck.name}`);
    
    res.json({
      success: true,
      data: posSettings
    });
    
  } catch (error) {
    console.error('❌ Error fetching POS settings by truck ID:', error);
    res.status(500).json({ success: false, message: 'Error fetching POS settings' });
  }
});

// Add missing social media endpoints
app.get('/api/social/accounts/:truckId', async (req, res) => {
  try {
    const { truckId } = req.params;
    
    // For now, return empty social accounts - can be expanded later
    res.json({
      success: true,
      data: {
        truckId,
        socialAccounts: {
          facebook: null,
          instagram: null,
          twitter: null,
          tiktok: null
        }
      }
    });
  } catch (error) {
    console.error('❌ Error fetching social accounts:', error);
    res.status(500).json({ success: false, message: 'Error fetching social accounts' });
  }
});

app.get('/api/social/posts', async (req, res) => {
  try {
    const { truckId, page = 1, limit = 3 } = req.query;
    
    // For now, return empty posts - can be expanded later with real social integration
    res.json({
      success: true,
      data: {
        posts: [],
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: 0,
          hasNext: false
        }
      }
    });
  } catch (error) {
    console.error('❌ Error fetching social posts:', error);
    res.status(500).json({ success: false, message: 'Error fetching social posts' });
  }
});

// Add missing reviews endpoint
app.get('/api/trucks/:id/reviews', async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 10, userId } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    console.log(`📝 Fetching reviews for truck ${id}, page ${page}, userId: ${userId}`);
    
    // Get reviews for this truck
    const reviews = await Review.find({ truckId: id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    // Add hasUserVotedHelpful field to each review
    const reviewsWithUserVote = reviews.map(review => {
      const reviewObj = review.toObject();
      reviewObj.hasUserVotedHelpful = userId ? review.helpfulVotes.includes(userId) : false;
      return reviewObj;
    });
    
    // Get total count for pagination
    const totalReviews = await Review.countDocuments({ truckId: id });
    
    // Calculate average rating
    const ratingStats = await Review.aggregate([
      { $match: { truckId: id } },
      { $group: { _id: null, averageRating: { $avg: '$rating' } } }
    ]);
    
    const averageRating = ratingStats.length > 0 ? ratingStats[0].averageRating : 0;
    
    res.json({
      success: true,
      data: {
        reviews: reviewsWithUserVote,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: totalReviews,
          hasNext: skip + reviewsWithUserVote.length < totalReviews
        },
        averageRating: Math.round(averageRating * 10) / 10 // Round to 1 decimal place
      }
    });
  } catch (error) {
    console.error('❌ Error fetching reviews:', error);
    res.status(500).json({ success: false, message: 'Error fetching reviews' });
  }
});

// Add new review endpoint
app.post('/api/trucks/:id/reviews', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, userName, rating, comment } = req.body;
    
    console.log(`📝 Adding review for truck ${id} by user ${userName}`);
    
    // Validate required fields
    if (!userId || !userName || !rating || !comment) {
      return res.status(400).json({ 
        success: false, 
        message: 'Missing required fields: userId, userName, rating, comment' 
      });
    }
    
    // Validate rating range
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ 
        success: false, 
        message: 'Rating must be between 1 and 5' 
      });
    }
    
    // Check if user already reviewed this truck
    const existingReview = await Review.findOne({ userId, truckId: id });
    if (existingReview) {
      return res.status(400).json({ 
        success: false, 
        message: 'You have already reviewed this food truck' 
      });
    }
    
    // Create new review
    const review = new Review({
      userId,
      truckId: id,
      userName,
      rating: parseInt(rating),
      comment: comment.trim()
    });
    
    await review.save();
    
    // Update truck's review count and average rating
    const allReviews = await Review.find({ truckId: id });
    const averageRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;
    
    await FoodTruck.findOneAndUpdate(
      { id },
      { 
        reviewCount: allReviews.length,
        rating: Math.round(averageRating * 10) / 10
      }
    );
    
    console.log(`✅ Review added successfully for truck ${id}`);
    
    res.json({
      success: true,
      message: 'Review added successfully',
      data: review
    });
    
  } catch (error) {
    console.error('❌ Error adding review:', error);
    res.status(500).json({ success: false, message: 'Error adding review' });
  }
});

// Respond to a review endpoint
app.post('/api/reviews/:id/respond', async (req, res) => {
  try {
    const { id } = req.params;
    const { response, respondedBy } = req.body;
    
    console.log(`💬 Adding response to review ${id} by ${respondedBy}`);
    
    // Validate required fields
    if (!response || !respondedBy) {
      return res.status(400).json({ 
        success: false, 
        message: 'Missing required fields: response, respondedBy' 
      });
    }
    
    // Find and update the review
    const review = await Review.findById(id);
    if (!review) {
      return res.status(404).json({ 
        success: false, 
        message: 'Review not found' 
      });
    }
    
    // Check if review already has a response
    if (review.response) {
      return res.status(400).json({ 
        success: false, 
        message: 'Review already has a response' 
      });
    }
    
    // Add the response
    review.response = {
      text: response.trim(),
      respondedAt: new Date(),
      respondedBy: respondedBy
    };
    review.updatedAt = new Date();
    
    await review.save();
    
    console.log(`✅ Response added to review ${id}`);
    
    res.json({
      success: true,
      message: 'Response added successfully',
      data: review
    });
    
  } catch (error) {
    console.error('❌ Error responding to review:', error);
    res.status(500).json({ success: false, message: 'Error responding to review' });
  }
});

// Mark review as helpful endpoint
app.post('/api/reviews/:id/helpful', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;
    
    console.log(`👍 Marking review ${id} as helpful by user ${userId}`);
    
    // Validate required fields
    if (!userId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Missing required field: userId' 
      });
    }
    
    // Find the review
    const review = await Review.findById(id);
    if (!review) {
      return res.status(404).json({ 
        success: false, 
        message: 'Review not found' 
      });
    }
    
    // Check if user already voted
    if (review.helpfulVotes.includes(userId)) {
      return res.status(400).json({ 
        success: false, 
        message: 'User has already marked this review as helpful' 
      });
    }
    
    // Add the vote
    review.helpfulVotes.push(userId);
    review.helpfulCount = review.helpfulVotes.length;
    review.updatedAt = new Date();
    
    await review.save();
    
    console.log(`✅ Review ${id} marked as helpful (total: ${review.helpfulCount})`);
    
    res.json({
      success: true,
      message: 'Review marked as helpful',
      data: {
        helpfulCount: review.helpfulCount,
        hasUserVotedHelpful: true
      }
    });
    
  } catch (error) {
    console.error('❌ Error marking review helpful:', error);
    res.status(500).json({ success: false, message: 'Error marking review helpful' });
  }
});

// Fix truck update endpoint to use custom id field
app.put('/api/trucks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`🔄 Updating truck with ID: ${id}`);
    
    // Use custom 'id' field instead of MongoDB's '_id'
    const truck = await FoodTruck.findOneAndUpdate(
      { id: id },
      { ...req.body, lastUpdated: new Date() },
      { new: true, runValidators: true }
    );
    
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found' });
    }
    
    // Clear relevant caches
    cache.delete(getCacheKey('trucks', 'all'));
    cache.delete(getCacheKey('truck', id));
    
    console.log(`✅ Truck updated successfully: ${truck.name}`);
    
    res.json({
      success: true,
      data: truck
    });
    
  } catch (error) {
    console.error('❌ Error updating truck:', error);
    res.status(500).json({ success: false, message: 'Error updating truck' });
  }
});

// =============================================================================
// POS INTEGRATION ENDPOINTS
// =============================================================================

// Get POS settings for a truck
app.get('/api/trucks/:id/pos-settings', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`📊 Getting POS settings for truck ${id}`);
    
    const truck = await FoodTruck.findOne({ id });
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found' });
    }
    
    // Return POS settings or default values
    const posSettings = truck.posSettings || {
      allowPosTracking: false,
      posApiKey: null,
      salesAnalytics: false,
      reportSettings: {
        weekly: false,
        monthly: false,
        quarterly: false,
        semiAnnually: false,
        annually: false
      }
    };
    
    res.json({
      success: true,
      posSettings: posSettings
    });
    
  } catch (error) {
    console.error('❌ Error getting POS settings:', error);
    res.status(500).json({ success: false, message: 'Error getting POS settings' });
  }
});

// Update POS settings for a truck
app.put('/api/trucks/:id/pos-settings', async (req, res) => {
  try {
    const { id } = req.params;
    const posSettings = req.body;
    console.log(`📊 Updating POS settings for truck ${id}`);
    
    const truck = await FoodTruck.findOneAndUpdate(
      { id },
      { 
        $set: { 
          posSettings: posSettings,
          updatedAt: new Date()
        }
      },
      { new: true }
    );
    
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found' });
    }
    
    // Clear relevant caches
    cache.delete(getCacheKey('trucks', 'all'));
    cache.delete(getCacheKey('truck', id));
    
    console.log(`✅ POS settings updated for truck: ${truck.name}`);
    
    res.json({
      success: true,
      data: truck
    });
    
  } catch (error) {
    console.error('❌ Error updating POS settings:', error);
    res.status(500).json({ success: false, message: 'Error updating POS settings' });
  }
});

// Test POS connection endpoint
app.post('/api/trucks/:id/pos-test', async (req, res) => {
  try {
    const { id } = req.params;
    const { posSystem } = req.body;
    console.log(`🔌 Testing POS connection for truck ${id} with system ${posSystem}`);
    
    const truck = await FoodTruck.findOne({ id });
    if (!truck) {
      return res.status(404).json({ success: false, message: 'Food truck not found' });
    }
    
    // Simulate POS connection test
    // In a real implementation, this would test actual API connections
    await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate delay
    
    const isConnected = Math.random() > 0.1; // 90% success rate for demo
    
    res.json({
      success: true,
      connected: isConnected,
      system: posSystem,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Error testing POS connection:', error);
    res.status(500).json({ success: false, message: 'Error testing POS connection' });
  }
});

// =============================================================================
// END POS INTEGRATION ENDPOINTS
// =============================================================================

// Start server
app.listen(PORT, () => {
  console.log(`🚚 Food Truck API Server running on port ${PORT}`);
  console.log(`🌐 Server URL: http://localhost:${PORT}`);
  console.log(`📋 API Documentation: http://localhost:${PORT}/api/health`);
});

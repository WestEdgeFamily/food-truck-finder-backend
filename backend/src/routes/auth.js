const express = require('express');
const router = express.Router();
const { registerOwner, registerUser, loginUser } = require('../controllers/authController');
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// Register routes
router.post('/register', registerOwner); // For food truck owners
router.post('/register-user', registerUser); // For customers
router.post('/login', loginUser);

// @route   POST /api/auth/register-customer
// @desc    Register a new customer
// @access  Public
router.post('/register-customer', async (req, res) => {
  try {
    const { name, email, password, phone, preferences } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    if (password.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }

    // Create customer user
    const user = new User({
      name,
      email,
      password,
      phone,
      role: 'customer',
      preferences: {
        notifications: {
          pushEnabled: true,
          emailEnabled: true,
          favoriteUpdates: true,
          nearbyTrucks: true,
          ...preferences?.notifications
        },
        location: {
          shareLocation: true,
          defaultRadius: 15,
          autoDetectLocation: true,
          ...preferences?.location
        },
        display: {
          theme: 'auto',
          language: 'en',
          showDistance: true,
          showPrices: true,
          ...preferences?.display
        }
      }
    });

    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user._id, 
        role: user.role,
        email: user.email 
      }, 
      process.env.JWT_SECRET, 
      { expiresIn: '30d' }
    );

    res.status(201).json({
      message: 'Customer registered successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        preferences: user.preferences
      }
    });

  } catch (error) {
    console.error('Customer registration error:', error);
    res.status(500).json({ message: 'Error registering customer', error: error.message });
  }
});

// @route   POST /api/auth/login-customer
// @desc    Customer login
// @access  Public
router.post('/login-customer', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Find customer user
    const user = await User.findOne({ email, role: 'customer' });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Update last login
    await user.updateLastLogin();

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user._id, 
        role: user.role,
        email: user.email 
      }, 
      process.env.JWT_SECRET, 
      { expiresIn: '30d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        preferences: user.preferences,
        favorites: user.favorites,
        activity: {
          totalVisits: user.activity.totalVisits,
          lastLogin: user.activity.lastLogin
        }
      }
    });

  } catch (error) {
    console.error('Customer login error:', error);
    res.status(500).json({ message: 'Error logging in', error: error.message });
  }
});

module.exports = router; 
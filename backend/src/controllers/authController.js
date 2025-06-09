const User = require('../models/User');
const FoodTruck = require('../models/FoodTruck');
const jwt = require('jsonwebtoken');
const config = require('../config/config');

// Generate JWT Token
const generateToken = (user) => {
    return jwt.sign(
        { 
            userId: user._id,
            email: user.email,
            role: user.role,
            name: user.name || user.businessName
        }, 
        config.JWT_SECRET,
        { expiresIn: '30d' }
    );
};

// @desc    Register a new food truck owner
// @route   POST /api/auth/register/owner
// @access  Public
const registerOwner = async (req, res) => {
    try {
        const { email, password, businessName, phoneNumber } = req.body;

        // Check if user exists
        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Create user with owner role
        const user = await User.create({
            email,
            password,
            businessName,
            phoneNumber,
            role: 'owner'
        });

        if (user) {
            // Create associated food truck
            const foodTruck = await FoodTruck.create({
                owner: user._id,
                name: businessName,
                isActive: false
            });

            console.log('Created user and food truck:', { user: user._id, foodTruck: foodTruck._id });

            const token = generateToken(user);
            res.status(201).json({
                _id: user._id,
                email: user.email,
                businessName: user.businessName,
                role: user.role,
                token,
                foodTruckId: foodTruck._id
            });
        }
    } catch (error) {
        console.error('Owner registration error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Register a new customer
// @route   POST /api/auth/register/customer
// @access  Public
const registerUser = async (req, res) => {
    try {
        const { email, password, name, phoneNumber, preferences } = req.body;

        // Check if user exists
        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        // Create user with customer role
        const user = await User.create({
            email,
            password,
            name,
            phoneNumber,
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

        if (user) {
            const token = generateToken(user);
            res.status(201).json({
                _id: user._id,
                email: user.email,
                name: user.name,
                role: user.role,
                preferences: user.preferences,
                token
            });
        }
    } catch (error) {
        console.error('User registration error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Login user (both customer and owner)
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await User.findOne({ email });
        
        if (!user) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        // Update last login
        await user.updateLastLogin();

        const token = jwt.sign(
            { userId: user._id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.json({
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Error logging in' });
    }
};

module.exports = {
    registerOwner,
    registerUser,
    loginUser
}; 
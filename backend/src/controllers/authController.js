const User = require('../models/User');
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
// @route   POST /api/auth/register
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
            role: 'owner',
            name: businessName // Use businessName as name for owners
        });

        if (user) {
            const token = generateToken(user);
            res.status(201).json({
                _id: user._id,
                email: user.email,
                businessName: user.businessName,
                role: user.role,
                token
            });
        }
    } catch (error) {
        console.error('Owner registration error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Register a new customer user
// @route   POST /api/auth/register-user
// @access  Public
const registerUser = async (req, res) => {
    try {
        const { email, password, name, phoneNumber } = req.body;

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
            role: 'customer'
        });

        if (user) {
            const token = generateToken(user);
            res.status(201).json({
                _id: user._id,
                email: user.email,
                name: user.name,
                role: user.role,
                token
            });
        }
    } catch (error) {
        console.error('User registration error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find user and include role
        const user = await User.findOne({ email }).select('+password');
        
        if (user && (await user.matchPassword(password))) {
            const token = generateToken(user);
            res.json({
                _id: user._id,
                email: user.email,
                name: user.name || user.businessName,
                role: user.role,
                token
            });
        } else {
            res.status(401).json({ message: 'Invalid email or password' });
        }
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

module.exports = {
    registerOwner,
    registerUser,
    loginUser
}; 
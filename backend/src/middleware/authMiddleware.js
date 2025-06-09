const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../config/config');

const protect = async (req, res, next) => {
    let token;
    console.log('Auth Headers:', req.headers.authorization); // Debug log

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            // Get token from header
            token = req.headers.authorization.split(' ')[1];
            console.log('Token received:', token); // Debug log

            // Verify token
            const decoded = jwt.verify(token, config.JWT_SECRET);
            console.log('Decoded token:', decoded); // Debug log

            // Get user from token
            const user = await User.findById(decoded.userId).select('-password');
            console.log('User found:', user ? { id: user._id, role: user.role } : 'No user'); // Debug log
            
            if (!user) {
                console.error('User not found with id:', decoded.userId);
                return res.status(401).json({ message: 'User not found' });
            }

            if (!user.isActive) {
                return res.status(401).json({ message: 'Account is deactivated' });
            }

            // Add user to request object
            req.user = {
                _id: user._id,
                userId: user._id,
                email: user.email,
                role: user.role,
                name: user.name || user.businessName,
                phoneNumber: user.phoneNumber
            };
            next();
        } catch (error) {
            console.error('Authentication error:', error);
            return res.status(401).json({ 
                message: 'Not authorized, token failed',
                error: error.message 
            });
        }
    } else {
        console.error('No authorization header or invalid format');
        return res.status(401).json({ message: 'Not authorized, no token provided' });
    }
};

// Middleware to ensure user is a food truck owner
const isOwner = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ message: 'User not authenticated' });
    }

    if (req.user.role !== 'owner') {
        return res.status(403).json({ message: 'Not authorized as food truck owner' });
    }

    next();
};

// Middleware to ensure user is a customer
const isCustomer = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ message: 'User not authenticated' });
    }

    if (req.user.role !== 'customer') {
        return res.status(403).json({ message: 'Not authorized as customer' });
    }

    next();
};

module.exports = {
    protect,
    isOwner,
    isCustomer
}; 
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
    let token;
    console.log('Auth Headers:', req.headers.authorization); // Debug log

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            // Get token from header
            token = req.headers.authorization.split(' ')[1];
            console.log('Token received:', token); // Debug log

            // Verify token
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key_here');
            console.log('Decoded token:', decoded); // Debug log

            // Get user from token
            const user = await User.findById(decoded.id).select('-password');
            console.log('User found:', user ? { id: user._id, role: user.role } : 'No user'); // Debug log
            
            if (!user) {
                console.error('User not found with id:', decoded.id);
                return res.status(401).json({ message: 'User not found' });
            }

            if (!user.isActive) {
                return res.status(401).json({ message: 'Account is deactivated' });
            }

            // Add user to request object
            req.user = user;
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
    console.log('Checking owner status for user:', { id: req.user._id, role: req.user.role }); // Debug log
    
    if (!req.user) {
        console.error('No user object found in request');
        return res.status(401).json({ message: 'User not authenticated' });
    }

    if (req.user.role !== 'owner') {
        console.error('User not authorized as owner:', { id: req.user._id, role: req.user.role });
        return res.status(403).json({ message: 'Not authorized as food truck owner' });
    }

    console.log('User authorized as owner'); // Debug log
    next();
};

module.exports = { protect, isOwner }; 
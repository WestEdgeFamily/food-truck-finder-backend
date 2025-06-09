const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../config/config');

exports.protect = async (req, res, next) => {
  try {
    let token;

    // Get token from header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ message: 'Not authorized to access this route' });
    }

    try {
      // Verify token
      const decoded = jwt.verify(token, config.JWT_SECRET);
      
      // Get user from database
      const user = await User.findById(decoded.userId);
      
      if (!user) {
        return res.status(401).json({ message: 'User not found' });
      }

      // Add user info to request
      req.user = {
        _id: user._id,
        userId: user._id,
        email: user.email,
        role: user.role,
        name: user.name,
        businessName: user.businessName,
        phoneNumber: user.phoneNumber
      };
      next();
    } catch (err) {
      console.error('Token verification error:', err);
      return res.status(401).json({ message: 'Not authorized to access this route' });
    }
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({ message: 'Error in auth middleware' });
  }
};

exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        message: `User role ${req.user ? req.user.role : 'undefined'} is not authorized to access this route`
      });
    }
    next();
  };
}; 
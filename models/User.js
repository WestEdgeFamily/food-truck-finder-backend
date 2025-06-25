const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  _id: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true
    // Note: Using plain text passwords to match server.js (not recommended for production)
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  role: {
    type: String,
    enum: ['customer', 'owner'],
    required: true
  },
  // Removed phone field - no phone numbers in the app
  businessName: {  // Added businessName field used in server.js
    type: String,
    trim: true
  },
  createdAt: {  // Added createdAt field used in server.js
    type: Date,
    default: Date.now
  }
  // Removed favorites array - using separate Favorite model instead
  // Removed bcrypt password hashing - using plain text to match server.js
  // Removed complex profile fields not used in server.js
});

module.exports = mongoose.model('User', userSchema); 
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  userId: {
    type: String,
    unique: true,
    sparse: true // Allows null values initially
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
    // Note: Properly hashed with bcrypt before saving (see pre-save middleware below)
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
  },
  lastLogin: {
    type: Date
  },
  isActive: {
    type: Boolean,
    default: true
  },
  refreshToken: {
    type: String
  }
  // Note: Using separate Favorite model for favorites functionality
  // Note: Passwords are properly hashed with bcrypt (see pre-save middleware below)
  // Note: Complex profile fields removed - keeping only fields used in server.js
});

// Index for better query performance
userSchema.index({ email: 1 });
userSchema.index({ role: 1 });
userSchema.index({ userId: 1 }); // For faster userId lookups
userSchema.index({ email: 1, role: 1 }); // Compound index for login queries

// Hash password before saving and set userId
userSchema.pre('save', async function(next) {
  // Set userId to match _id if not already set
  if (this.isNew && !this.userId) {
    this.userId = this._id.toString();
  }
  
  // Only hash the password if it has been modified (or is new)
  if (!this.isModified('password')) return next();
  
  try {
    // Generate salt and hash password
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare password for login
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw error;
  }
};

// Method to generate JWT payload
userSchema.methods.toAuthJSON = function() {
  return {
    _id: this._id.toString(),
    id: this._id.toString(),
    email: this.email,
    name: this.name,
    role: this.role,
    businessName: this.businessName
  };
};

// Remove password from JSON responses
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  delete obj.refreshToken;
  return obj;
};

module.exports = mongoose.model('User', userSchema); 
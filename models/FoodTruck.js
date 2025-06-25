const mongoose = require('mongoose');

const foodTruckSchema = new mongoose.Schema({
  id: { 
    type: String, 
    required: true, 
    unique: true 
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  businessName: {
    type: String,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  ownerId: {
    type: String,  // Changed from ObjectId to String to match server.js
    required: true
  },
  cuisine: {  // Changed from cuisineTypes array to single cuisine string
    type: String,
    trim: true,
    default: 'American'
  },
  image: {
    type: String
  },
  // Removed phone field - no phone numbers in the app
  email: {
    type: String,
    trim: true,
    lowercase: true
  },
  website: {
    type: String,
    trim: true
  },
  location: {
    latitude: {
      type: Number
    },
    longitude: {
      type: Number
    },
    address: {
      type: String,
      trim: true
    }
  },
  hours: {  // Added hours field used in server.js
    type: String,
    default: 'Hours to be set by owner'
  },
  schedule: {
    type: mongoose.Schema.Types.Mixed
  },
  menu: [{
    name: { type: String, required: true },
    description: String,
    price: { type: Number, required: true },
    category: String,
    image: String,
    isAvailable: { type: Boolean, default: true }
  }],
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  reviewCount: {
    type: Number,
    default: 0
  },
  isOpen: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Added fields used in server.js
  createdAt: {
    type: Date,
    default: Date.now
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  // POS Integration fields used in server.js
  posSettings: {
    parentAccountId: String,
    childAccounts: [String],
    allowPosTracking: { type: Boolean, default: true },
    posApiKey: String,
    posWebhookUrl: String
  }
});

// Index for location-based queries
foodTruckSchema.index({ 'location.latitude': 1, 'location.longitude': 1 });

// Index for text search - updated to use single cuisine field
foodTruckSchema.index({ name: 'text', description: 'text', cuisine: 'text' });

module.exports = mongoose.model('FoodTruck', foodTruckSchema); 
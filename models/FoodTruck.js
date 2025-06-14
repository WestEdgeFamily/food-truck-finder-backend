const mongoose = require('mongoose');

const foodTruckSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  businessName: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  ownerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  cuisineTypes: [{
    type: String,
    trim: true
  }],
  image: {
    type: String
  },
  phone: {
    type: String,
    trim: true
  },
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
  }
}, {
  timestamps: true
});

// Index for location-based queries
foodTruckSchema.index({ 'location.latitude': 1, 'location.longitude': 1 });

// Index for text search
foodTruckSchema.index({ name: 'text', description: 'text', cuisineTypes: 'text' });

module.exports = mongoose.model('FoodTruck', foodTruckSchema);

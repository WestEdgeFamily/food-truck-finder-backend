const mongoose = require('mongoose');

const foodTruckSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true, trim: true },
  businessName: { type: String, trim: true },
  description: { type: String, required: true },
  cuisine: { type: String, trim: true, default: 'American' },
  rating: { type: Number, default: 0, min: 0, max: 5 },
  image: { type: String },
  images: [{
    url: { type: String, required: true },
    type: { type: String, default: 'gallery' },
    uploadedAt: { type: Date, default: Date.now }
  }],
  email: { type: String, trim: true, lowercase: true },
  website: { type: String, trim: true },
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], index: '2dsphere' }, // [longitude, latitude]
    latitude: { type: Number },
    longitude: { type: Number },
    address: { type: String, trim: true }
  },
  hours: { type: String, default: 'Hours to be set by owner' },
  menu: [{
    name: { type: String, required: true },
    description: String,
    price: { type: Number, required: true },
    category: String,
    image: String,
    isAvailable: { type: Boolean, default: true }
  }],
  ownerId: { type: String, required: true },
  isOpen: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  schedule: {
    type: mongoose.Schema.Types.Mixed
  },
  posSettings: {
    parentAccountId: String,
    childAccounts: [String],
    allowPosTracking: { type: Boolean, default: true },
    posApiKey: String,
    posWebhookUrl: String
  },
  createdAt: { type: Date, default: Date.now },
  lastUpdated: { type: Date, default: Date.now },
  reviewCount: { type: Number, default: 0 }
});

// Geospatial index for location-based queries (replaces old lat/lng index)
foodTruckSchema.index({ 'location.coordinates': '2dsphere' });

// Keep backward compatibility index
foodTruckSchema.index({ 'location.latitude': 1, 'location.longitude': 1 });

// Text search index
foodTruckSchema.index({ name: 'text', description: 'text', cuisine: 'text' });

// Performance indexes
foodTruckSchema.index({ ownerId: 1 });
foodTruckSchema.index({ cuisine: 1 });
foodTruckSchema.index({ isActive: 1, isOpen: 1 });

// Pre-save middleware to set coordinates array
foodTruckSchema.pre('save', function(next) {
  if (this.location && this.location.latitude && this.location.longitude) {
    this.location.coordinates = [this.location.longitude, this.location.latitude];
  }
  next();
});

module.exports = mongoose.model('FoodTruck', foodTruckSchema);

const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  truckId: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

// Ensure a user can't favorite the same truck twice
favoriteSchema.index({ userId: 1, truckId: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema); 

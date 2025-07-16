const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true
  },
  truckId: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Create compound index to prevent duplicate favorites
favoriteSchema.index({ userId: 1, truckId: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema);

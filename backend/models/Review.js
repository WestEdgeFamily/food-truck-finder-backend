const mongoose = require('mongoose');

const reviewResponseSchema = new mongoose.Schema({
  text: {
    type: String,
    required: true,
    trim: true
  },
  respondedAt: {
    type: Date,
    default: Date.now
  },
  respondedBy: {
    type: String,
    required: true
  }
});

const reviewSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true
  },
  truckId: {
    type: String,
    required: true
  },
  userName: {
    type: String,
    required: true
  },
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  comment: {
    type: String,
    required: true,
    trim: true
  },
  photos: {
    type: [String],
    default: []
  },
  helpfulCount: {
    type: Number,
    default: 0
  },
  helpfulVotes: {
    type: [String], // Array of user IDs who marked this helpful
    default: []
  },
  response: {
    type: reviewResponseSchema,
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update updatedAt before saving
reviewSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('Review', reviewSchema);

const mongoose = require('mongoose');

const socialAccountSchema = new mongoose.Schema({
  ownerId: {
    type: String,
    required: true,
    index: true
  },
  truckId: {
    type: String,
    required: true
  },
  platform: {
    type: String,
    enum: ['instagram', 'facebook', 'twitter', 'linkedin', 'tiktok'],
    required: true
  },
  accountName: String,
  accountId: String,
  accessToken: {
    type: String,
    required: true
  },
  refreshToken: String,
  tokenExpiry: Date,
  profileImage: String,
  followers: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  permissions: [String], // e.g., ['publish_content', 'read_insights', 'manage_comments']
  lastSync: Date
}, {
  timestamps: true
});

// Compound index for unique platform per truck
socialAccountSchema.index({ truckId: 1, platform: 1 }, { unique: true });

// Method to check if token is expired
socialAccountSchema.methods.isTokenExpired = function() {
  if (!this.tokenExpiry) return false;
  return new Date() > this.tokenExpiry;
};

// Method to update follower count
socialAccountSchema.methods.updateFollowers = async function(count) {
  this.followers = count;
  this.lastSync = new Date();
  return this.save();
};

module.exports = mongoose.model('SocialAccount', socialAccountSchema);

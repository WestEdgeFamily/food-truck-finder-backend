const mongoose = require('mongoose');

const socialPostSchema = new mongoose.Schema({
  truckId: {
    type: String,
    required: true,
    index: true
  },
  ownerId: {
    type: String,
    required: true
  },
  // Content
  content: {
    text: {
      type: String,
      maxLength: 2200 // Instagram's limit
    },
    hashtags: [String],
    mentions: [String],
    images: [{
      url: String,
      alt: String,
      width: Number,
      height: Number
    }],
    link: String
  },
  // Scheduling
  status: {
    type: String,
    enum: ['draft', 'scheduled', 'published', 'failed', 'deleted'],
    default: 'draft'
  },
  scheduledTime: Date,
  publishedTime: Date,
  // Platforms
  platforms: [{
    name: {
      type: String,
      enum: ['instagram', 'facebook', 'twitter', 'linkedin', 'tiktok']
    },
    postId: String, // Platform-specific post ID
    status: String, // Platform-specific status
    error: String,
    url: String // Direct link to the post
  }],
  // Template info
  isTemplate: {
    type: Boolean,
    default: false
  },
  templateName: String,
  templateCategory: String, // 'daily-special', 'location-update', 'new-menu', etc.
  // Analytics
  analytics: {
    impressions: { type: Number, default: 0 },
    reach: { type: Number, default: 0 },
    engagement: { type: Number, default: 0 },
    likes: { type: Number, default: 0 },
    comments: { type: Number, default: 0 },
    shares: { type: Number, default: 0 },
    saves: { type: Number, default: 0 },
    clicks: { type: Number, default: 0 },
    lastUpdated: Date
  },
  // AI Generated content
  aiGenerated: {
    type: Boolean,
    default: false
  },
  aiPrompt: String,
  // Campaign
  campaignId: String,
  campaignName: String
}, {
  timestamps: true
});

// Indexes for efficient queries
socialPostSchema.index({ truckId: 1, status: 1, scheduledTime: 1 });
socialPostSchema.index({ truckId: 1, isTemplate: 1 });
socialPostSchema.index({ 'platforms.postId': 1 });

// Virtual for engagement rate
socialPostSchema.virtual('engagementRate').get(function() {
  if (!this.analytics.reach || this.analytics.reach === 0) return 0;
  return ((this.analytics.engagement / this.analytics.reach) * 100).toFixed(2);
});

// Method to update analytics
socialPostSchema.methods.updateAnalytics = function(newData) {
  Object.assign(this.analytics, newData);
  this.analytics.lastUpdated = new Date();
  return this.save();
};

// Method to publish post
socialPostSchema.methods.markAsPublished = function(platformName, postId, url) {
  const platform = this.platforms.find(p => p.name === platformName);
  if (platform) {
    platform.postId = postId;
    platform.status = 'published';
    platform.url = url;
  }
  
  // Update overall status if all platforms are published
  const allPublished = this.platforms.every(p => p.status === 'published');
  if (allPublished) {
    this.status = 'published';
    this.publishedTime = new Date();
  }
  
  return this.save();
};

// Static method to get scheduled posts
socialPostSchema.statics.getScheduledPosts = function(truckId, startDate, endDate) {
  return this.find({
    truckId,
    status: 'scheduled',
    scheduledTime: {
      $gte: startDate,
      $lte: endDate
    }
  }).sort({ scheduledTime: 1 });
};

// Static method to get post templates
socialPostSchema.statics.getTemplates = function(truckId, category) {
  const query = { truckId, isTemplate: true };
  if (category) query.templateCategory = category;
  return this.find(query).sort({ createdAt: -1 });
};

module.exports = mongoose.model('SocialPost', socialPostSchema); 
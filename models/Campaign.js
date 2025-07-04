const mongoose = require('mongoose');

const campaignSchema = new mongoose.Schema({
  truckId: {
    type: String,
    required: true,
    index: true
  },
  ownerId: {
    type: String,
    required: true
  },
  name: {
    type: String,
    required: true
  },
  description: String,
  type: {
    type: String,
    enum: ['promotion', 'contest', 'event', 'seasonal', 'product-launch', 'awareness'],
    required: true
  },
  status: {
    type: String,
    enum: ['draft', 'active', 'paused', 'completed', 'cancelled'],
    default: 'draft'
  },
  // Campaign duration
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  // Campaign goals
  goals: {
    targetReach: Number,
    targetEngagement: Number,
    targetSales: Number,
    targetNewCustomers: Number
  },
  // Campaign budget (if running paid ads)
  budget: {
    total: Number,
    spent: Number,
    currency: {
      type: String,
      default: 'USD'
    }
  },
  // Platforms
  platforms: [{
    type: String,
    enum: ['instagram', 'facebook', 'twitter', 'linkedin', 'tiktok']
  }],
  // Hashtags and keywords
  hashtags: [String],
  keywords: [String],
  // Promotional details
  promotion: {
    discountType: String, // 'percentage', 'fixed', 'bogo', etc.
    discountValue: Number,
    promoCode: String,
    terms: String
  },
  // Contest details
  contest: {
    rules: String,
    prizes: [String],
    entryMethods: [String], // 'follow', 'like', 'comment', 'share', 'tag'
    winnerSelection: String, // 'random', 'judged', 'most-likes'
    winnersCount: Number
  },
  // Analytics
  analytics: {
    totalPosts: { type: Number, default: 0 },
    totalReach: { type: Number, default: 0 },
    totalEngagement: { type: Number, default: 0 },
    totalClicks: { type: Number, default: 0 },
    conversionRate: { type: Number, default: 0 },
    roi: { type: Number, default: 0 },
    newFollowers: { type: Number, default: 0 },
    lastUpdated: Date
  },
  // Associated posts
  postIds: [String]
}, {
  timestamps: true
});

// Index for active campaigns
campaignSchema.index({ truckId: 1, status: 1, startDate: 1, endDate: 1 });

// Virtual for campaign progress
campaignSchema.virtual('progress').get(function() {
  const now = new Date();
  if (now < this.startDate) return 0;
  if (now > this.endDate) return 100;
  
  const total = this.endDate - this.startDate;
  const elapsed = now - this.startDate;
  return Math.round((elapsed / total) * 100);
});

// Virtual for days remaining
campaignSchema.virtual('daysRemaining').get(function() {
  const now = new Date();
  if (now > this.endDate) return 0;
  
  const diff = this.endDate - now;
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
});

// Method to update analytics
campaignSchema.methods.updateAnalytics = function(metrics) {
  Object.assign(this.analytics, metrics);
  this.analytics.lastUpdated = new Date();
  
  // Calculate ROI if budget is set
  if (this.budget && this.budget.spent > 0 && metrics.revenue) {
    this.analytics.roi = ((metrics.revenue - this.budget.spent) / this.budget.spent) * 100;
  }
  
  return this.save();
};

// Method to add post to campaign
campaignSchema.methods.addPost = function(postId) {
  if (!this.postIds.includes(postId)) {
    this.postIds.push(postId);
    this.analytics.totalPosts += 1;
  }
  return this.save();
};

// Static method to get active campaigns
campaignSchema.statics.getActiveCampaigns = function(truckId) {
  const now = new Date();
  return this.find({
    truckId,
    status: 'active',
    startDate: { $lte: now },
    endDate: { $gte: now }
  });
};

module.exports = mongoose.model('Campaign', campaignSchema); 
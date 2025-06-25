const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  // Let MongoDB auto-generate _id (ObjectId)
  // Don't manually set _id unless necessary
  
  name: {
    type: String,
    required: true,
    trim: true
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
    // In production, this should be hashed with bcrypt
  },
  
  role: {
    type: String,
    enum: ['customer', 'owner'],
    required: true
  },
  
  businessName: {
    type: String,
    required: function() {
      return this.role === 'owner';
    }
  },
  
  // Legacy field for compatibility - will be set to match _id
  userId: {
    type: String,
    index: true
  },
  
  // Profile information
  phone: {
    type: String,
    trim: true
  },
  
  address: {
    street: String,
    city: String,
    state: String,
    zipCode: String
  },
  
  // Preferences
  preferences: {
    notifications: {
      type: Boolean,
      default: true
    },
    newsletter: {
      type: Boolean,
      default: false
    }
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  },
  
  lastLoginAt: {
    type: Date
  }
}, {
  // Add automatic timestamps
  timestamps: true,
  
  // Transform output to ensure consistent ID fields
  toJSON: {
    transform: function(doc, ret) {
      // Ensure all ID fields are consistent
      ret.id = ret._id.toString();
      ret.userId = ret._id.toString();
      
      // Don't expose password in JSON
      delete ret.password;
      
      return ret;
    }
  }
});

// Indexes for better performance
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ userId: 1 });
userSchema.index({ role: 1 });
userSchema.index({ createdAt: -1 });

// Pre-save middleware to ensure userId matches _id
userSchema.pre('save', function(next) {
  // Set userId to match _id for consistency
  if (this._id && (!this.userId || this.userId !== this._id.toString())) {
    this.userId = this._id.toString();
  }
  
  // Update the updatedAt timestamp
  this.updatedAt = new Date();
  
  next();
});

// Instance methods
userSchema.methods.toSafeObject = function() {
  const userObject = this.toObject();
  delete userObject.password;
  return userObject;
};

// Static methods
userSchema.statics.findByIdentifier = async function(identifier) {
  // Try different ways to find the user
  let user = null;
  
  // Try as ObjectId
  if (mongoose.Types.ObjectId.isValid(identifier)) {
    user = await this.findById(identifier);
    if (user) return user;
  }
  
  // Try as email
  user = await this.findOne({ email: identifier });
  if (user) return user;
  
  // Try as userId field
  user = await this.findOne({ userId: identifier });
  if (user) return user;
  
  return null;
};

module.exports = mongoose.model('User', userSchema);

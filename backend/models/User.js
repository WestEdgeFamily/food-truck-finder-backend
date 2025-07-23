const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
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
    required: true,
    minlength: 8
  },
  role: {
    type: String,
    enum: ['customer', 'owner', 'admin'],
    default: 'customer'
  },
  businessName: {
    type: String,
    trim: true
  },
  // Business verification fields
  businessVerification: {
    isVerified: {
      type: Boolean,
      default: false
    },
    verificationStatus: {
      type: String,
      enum: ['pending', 'approved', 'rejected', 'not_submitted', 'pending_manual_review'],
      default: 'not_submitted'
    },
    businessLicenseNumber: String,
    foodServicePermit: String,
    businessType: String,
    yearsInBusiness: String,
    businessState: String,
    businessPhone: String,
    businessEmail: String,
    ein: String, // Employer Identification Number for automated verification
    submittedAt: Date,
    reviewedAt: Date,
    reviewedBy: String,
    rejectionReason: String,
    approvalMethod: {
      type: String,
      enum: ['automated', 'manual'],
      default: 'manual'
    },
    
    // 🤖 Automated Verification Results
    automatedVerification: {
      attempted: { type: Boolean, default: false },
      score: { type: Number, default: 0 }, // 0-100 confidence score
      confidence: { type: Number, default: 0 },
      autoApproved: { type: Boolean, default: false },
      requiresManualReview: { type: Boolean, default: false },
      completedAt: Date,
      
      // Individual check results
      checks: {
        ein: {
          verified: { type: Boolean, default: false },
          confidence: { type: Number, default: 0 },
          details: mongoose.Schema.Types.Mixed
        },
        stateRegistration: {
          verified: { type: Boolean, default: false },
          confidence: { type: Number, default: 0 },
          details: mongoose.Schema.Types.Mixed
        },
        foodPermit: {
          verified: { type: Boolean, default: false },
          confidence: { type: Number, default: 0 },
          details: mongoose.Schema.Types.Mixed
        },
        businessLicense: {
          verified: { type: Boolean, default: false },
          confidence: { type: Number, default: 0 },
          details: mongoose.Schema.Types.Mixed
        }
      }
    }
  },
  userId: {
    type: String,
    unique: true,
    sparse: true
  },
  refreshToken: {
    type: String
  },
  lastLogin: {
    type: Date
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

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Set userId to match _id before saving
userSchema.pre('save', function(next) {
  if (!this.userId) {
    this.userId = this._id.toString();
  }
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('User', userSchema);

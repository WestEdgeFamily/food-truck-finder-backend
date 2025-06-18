const mongoose = require('mongoose');

const menuItemSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  price: {
    type: Number,
    required: true
  },
  isAvailable: {
    type: Boolean,
    default: true
  }
});

const scheduleSchema = new mongoose.Schema({
  monday: {
    open: String,
    close: String,
    isOpen: Boolean
  },
  tuesday: {
    open: String,
    close: String,
    isOpen: Boolean
  },
  wednesday: {
    open: String,
    close: String,
    isOpen: Boolean
  },
  thursday: {
    open: String,
    close: String,
    isOpen: Boolean
  },
  friday: {
    open: String,
    close: String,
    isOpen: Boolean
  },
  saturday: {
    open: String,
    close: String,
    isOpen: Boolean
  },
  sunday: {
    open: String,
    close: String,
    isOpen: Boolean
  }
});

const foodTruckSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  businessName: {
    type: String
  },
  description: {
    type: String,
    required: true
  },
  ownerId: {
    type: String,
    required: true
  },
  cuisine: {
    type: String,
    required: true
  },
  image: {
    type: String
  },
  email: {
    type: String
  },
  website: {
    type: String
  },
  location: {
    latitude: {
      type: Number
    },
    longitude: {
      type: Number
    },
    address: {
      type: String
    }
  },
  hours: {
    type: String
  },
  menu: [menuItemSchema],
  schedule: scheduleSchema,
  rating: {
    type: Number,
    default: 0
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
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  posSettings: {
    childAccounts: [{
      id: String,
      name: String,
      apiKey: String,
      permissions: [String],
      createdAt: String,
      isActive: Boolean
    }],
    allowPosTracking: {
      type: Boolean,
      default: true
    }
  }
});

module.exports = mongoose.model('FoodTruck', foodTruckSchema);

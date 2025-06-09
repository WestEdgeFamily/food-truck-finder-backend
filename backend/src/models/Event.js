const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  eventType: {
    type: String,
    enum: ['festival', 'market', 'private', 'street_fair', 'concert', 'sports', 'corporate', 'other'],
    default: 'festival'
  },
  location: {
    address: {
      type: String,
      required: true
    },
    city: {
      type: String,
      required: true
    },
    state: {
      type: String,
      required: true
    },
    zipCode: {
      type: String
    },
    venue: {
      type: String
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      index: '2dsphere'
    }
  },
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  startTime: {
    type: String, // Format: "HH:mm"
    required: true
  },
  endTime: {
    type: String, // Format: "HH:mm"
    required: true
  },
  organizer: {
    name: {
      type: String,
      required: true
    },
    email: {
      type: String
    },
    phone: {
      type: String
    },
    website: {
      type: String
    }
  },
  participatingTrucks: [{
    truck: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'FoodTruck'
    },
    confirmedAt: {
      type: Date,
      default: Date.now
    },
    status: {
      type: String,
      enum: ['invited', 'confirmed', 'declined', 'waitlist'],
      default: 'confirmed'
    },
    specialNotes: String
  }],
  maxTrucks: {
    type: Number,
    default: 20
  },
  registrationDeadline: {
    type: Date
  },
  entryFee: {
    type: Number,
    default: 0
  },
  expectedAttendance: {
    type: Number
  },
  amenities: [{
    type: String,
    enum: ['electricity', 'water', 'waste_disposal', 'security', 'parking', 'wifi', 'restrooms', 'seating', 'stage', 'music']
  }],
  requirements: [{
    type: String // e.g., "Food handler's permit required", "Insurance certificate needed"
  }],
  tags: [{
    type: String,
    trim: true
  }],
  isPublic: {
    type: Boolean,
    default: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  weatherContingency: {
    type: String // Rain plan, etc.
  },
  socialMedia: {
    website: String,
    facebook: String,
    instagram: String,
    twitter: String
  },
  images: [{
    url: String,
    caption: String
  }],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

// Indexes
eventSchema.index({ startDate: 1, endDate: 1 });
eventSchema.index({ 'location.coordinates': '2dsphere' });
eventSchema.index({ eventType: 1 });
eventSchema.index({ isActive: 1, isPublic: 1 });

// Virtual for event status
eventSchema.virtual('status').get(function() {
  const now = new Date();
  if (this.endDate < now) return 'completed';
  if (this.startDate <= now && this.endDate >= now) return 'active';
  return 'upcoming';
});

// Virtual for duration in hours
eventSchema.virtual('durationHours').get(function() {
  const start = new Date(`2000-01-01T${this.startTime}`);
  const end = new Date(`2000-01-01T${this.endTime}`);
  return (end - start) / (1000 * 60 * 60);
});

// Method to check if a truck can join
eventSchema.methods.canTruckJoin = function() {
  const confirmedTrucks = this.participatingTrucks.filter(pt => pt.status === 'confirmed').length;
  return confirmedTrucks < this.maxTrucks && new Date() < this.registrationDeadline;
};

// Method to add truck to event
eventSchema.methods.addTruck = function(truckId, status = 'confirmed') {
  const existingTruck = this.participatingTrucks.find(pt => pt.truck.toString() === truckId.toString());
  
  if (existingTruck) {
    existingTruck.status = status;
    existingTruck.confirmedAt = new Date();
  } else {
    this.participatingTrucks.push({
      truck: truckId,
      status: status,
      confirmedAt: new Date()
    });
  }
  
  return this.save();
};

// Method to remove truck from event
eventSchema.methods.removeTruck = function(truckId) {
  this.participatingTrucks = this.participatingTrucks.filter(
    pt => pt.truck.toString() !== truckId.toString()
  );
  return this.save();
};

module.exports = mongoose.model('Event', eventSchema); 
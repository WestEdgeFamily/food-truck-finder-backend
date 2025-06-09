const mongoose = require('mongoose');

const foodTruckSchema = new mongoose.Schema({
    owner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Name is required']
    },
    businessName: {
        type: String,
        required: [true, 'Business name is required']
    },
    phoneNumber: {
        type: String,
        required: [true, 'Phone number is required']
    },
    description: {
        type: String,
        default: ''
    },
    cuisineType: {
        type: String,
        default: 'American'
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number],
            default: [0, 0]
        },
        address: String,
        city: String,
        state: String,
        // Social media tracking fields
        lastUpdated: {
            type: Date,
            default: Date.now
        },
        source: {
            type: String,
            enum: ['gps', 'instagram', 'facebook', 'twitter', 'owner', 'customer', 'admin', 'manual'],
            default: 'manual'
        },
        confidence: {
            type: String,
            enum: ['high', 'medium', 'low'],
            default: 'medium'
        },
        notes: String,
        // GPS tracking fields (commented out for future use)
        // gpsDeviceId: String,
        // gpsLastUpdate: Date,
        // gpsAccuracy: Number
    },
    // Social media integration
    socialMedia: {
        instagram: {
            username: String,
            lastChecked: Date,
            autoTrack: {
                type: Boolean,
                default: false
            }
        },
        facebook: {
            pageId: String,
            pageName: String,
            lastChecked: Date,
            autoTrack: {
                type: Boolean,
                default: false
            }
        },
        twitter: {
            username: String,
            lastChecked: Date,
            autoTrack: {
                type: Boolean,
                default: false
            }
        }
    },
    // Location tracking history
    locationHistory: [{
        coordinates: [Number],
        address: String,
        city: String,
        state: String,
        timestamp: {
            type: Date,
            default: Date.now
        },
        source: {
            type: String,
            enum: ['gps', 'instagram', 'facebook', 'twitter', 'owner', 'customer', 'admin', 'manual']
        },
        confidence: {
            type: String,
            enum: ['high', 'medium', 'low'],
            default: 'medium'
        },
        notes: String,
        reportedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    }],
    foodTypes: [{
        type: String,
        trim: true
    }],
    businessHours: [{
        day: {
            type: String,
            enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
            required: true
        },
        open: {
            type: String,
            required: true
        },
        close: {
            type: String,
            required: true
        }
    }],
    isActive: {
        type: Boolean,
        default: false
    },
    isCurrentlyOpen: {
        type: Boolean,
        default: false
    },
    // Tracking preferences
    trackingPreferences: {
        allowCustomerReports: {
            type: Boolean,
            default: true
        },
        requireLocationVerification: {
            type: Boolean,
            default: false
        },
        autoPostToSocial: {
            type: Boolean,
            default: false
        },
        // GPS tracking preferences (commented out for future use)
        // enableGpsTracking: {
        //     type: Boolean,
        //     default: false
        // },
        // gpsUpdateFrequency: {
        //     type: Number,
        //     default: 60 // seconds
        // },
        // businessHoursOnly: {
        //     type: Boolean,
        //     default: true
        // }
    },
    rating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
    },
    totalReviews: {
        type: Number,
        default: 0
    },
    ratings: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        rating: {
            type: Number,
            required: true,
            min: 1,
            max: 5
        },
        review: String,
        date: {
            type: Date,
            default: Date.now
        }
    }],
    averageRating: {
        type: Number,
        default: 0
    },
    images: [{
        type: String
    }],
    menu: [{
        name: {
            type: String,
            required: true
        },
        description: String,
        price: {
            type: Number,
            required: true
        },
        category: {
            type: String,
            required: true
        },
        available: {
            type: Boolean,
            default: true
        }
    }]
}, {
    timestamps: true
});

// Create index for location-based queries
foodTruckSchema.index({ location: '2dsphere' });

const FoodTruck = mongoose.model('FoodTruck', foodTruckSchema);

module.exports = FoodTruck; 
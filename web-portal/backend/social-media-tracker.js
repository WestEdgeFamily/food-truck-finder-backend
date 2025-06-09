const mongoose = require('mongoose');
const FoodTruck = require('./src/models/FoodTruck');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/foodtruck', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Sample social media location updates (simulated)
const socialMediaUpdates = [
  {
    truckName: "Taco Fiesta",
    source: "instagram",
    location: {
      latitude: 40.7589,
      longitude: -73.9851,
      address: "Times Square, NYC",
      city: "New York",
      state: "NY",
      confidence: "medium",
      notes: "Posted Instagram story with location tag"
    }
  },
  {
    truckName: "Seoul Food",
    source: "facebook",
    location: {
      latitude: 34.0522,
      longitude: -118.2437,
      address: "Downtown LA Food Court",
      city: "Los Angeles", 
      state: "CA",
      confidence: "high",
      notes: "Facebook check-in at specific location"
    }
  },
  {
    truckName: "Sushi Express",
    source: "twitter",
    location: {
      latitude: 37.7749,
      longitude: -122.4194,
      address: "Golden Gate Park",
      city: "San Francisco",
      state: "CA", 
      confidence: "low",
      notes: "Twitter mention of location (not verified)"
    }
  }
];

// Function to simulate social media tracking
async function simulateSocialMediaTracking() {
  console.log('🤖 Starting social media tracking simulation...');
  
  for (const update of socialMediaUpdates) {
    try {
      // Find the food truck by name
      const foodTruck = await FoodTruck.findOne({ 
        businessName: { $regex: update.truckName, $options: 'i' }
      });
      
      if (!foodTruck) {
        console.log(`❌ Food truck "${update.truckName}" not found`);
        continue;
      }

      // Save current location to history before updating
      if (foodTruck.location && foodTruck.location.coordinates[0] !== 0 && foodTruck.location.coordinates[1] !== 0) {
        foodTruck.locationHistory.push({
          coordinates: foodTruck.location.coordinates,
          address: foodTruck.location.address,
          city: foodTruck.location.city,
          state: foodTruck.location.state,
          source: foodTruck.location.source,
          confidence: foodTruck.location.confidence,
          notes: foodTruck.location.notes,
          timestamp: foodTruck.location.lastUpdated || new Date()
        });
      }

      // Update location from social media
      foodTruck.location = {
        type: 'Point',
        coordinates: [update.location.longitude, update.location.latitude],
        address: update.location.address,
        city: update.location.city,
        state: update.location.state,
        source: update.source,
        confidence: update.location.confidence,
        notes: update.location.notes,
        lastUpdated: new Date()
      };

      // Also add to location history
      foodTruck.locationHistory.push({
        coordinates: [update.location.longitude, update.location.latitude],
        address: update.location.address,
        city: update.location.city,
        state: update.location.state,
        source: update.source,
        confidence: update.location.confidence,
        notes: update.location.notes,
        timestamp: new Date()
      });

      await foodTruck.save();
      
      console.log(`✅ Updated ${update.truckName} location from ${update.source}`);
      console.log(`   📍 ${update.location.address}`);
      console.log(`   🎯 Confidence: ${update.location.confidence}`);
      
    } catch (error) {
      console.error(`❌ Error updating ${update.truckName}:`, error.message);
    }
  }
  
  console.log('🎉 Social media tracking simulation complete!');
}

// Function to simulate customer reports
async function simulateCustomerReports() {
  console.log('👥 Starting customer location reports simulation...');
  
  const customerReports = [
    {
      truckName: "Pizza on Wheels",
      location: {
        latitude: 41.8781,
        longitude: -87.6298,
        address: "Millennium Park", 
        city: "Chicago",
        state: "IL",
        notes: "Saw truck serving lunch crowd near the bean"
      }
    },
    {
      truckName: "Smokin' BBQ",
      location: {
        latitude: 30.2672,
        longitude: -97.7431,
        address: "Austin City Limits Festival",
        city: "Austin", 
        state: "TX",
        notes: "Long line, amazing brisket!"
      }
    }
  ];

  for (const report of customerReports) {
    try {
      const foodTruck = await FoodTruck.findOne({ 
        businessName: { $regex: report.truckName, $options: 'i' }
      });
      
      if (!foodTruck) {
        console.log(`❌ Food truck "${report.truckName}" not found`);
        continue;
      }

      // Add to location history (customer reports might not always update main location)
      foodTruck.locationHistory.push({
        coordinates: [report.location.longitude, report.location.latitude],
        address: report.location.address,
        city: report.location.city,
        state: report.location.state,
        source: 'customer',
        confidence: 'medium',
        notes: report.location.notes,
        timestamp: new Date()
      });

      // If truck allows customer reports and doesn't require verification, update main location
      if (foodTruck.trackingPreferences?.allowCustomerReports && 
          !foodTruck.trackingPreferences?.requireLocationVerification) {
        
        // Save current location to history first
        if (foodTruck.location && foodTruck.location.coordinates[0] !== 0) {
          foodTruck.locationHistory.push({
            coordinates: foodTruck.location.coordinates,
            address: foodTruck.location.address,
            city: foodTruck.location.city,
            state: foodTruck.location.state,
            source: foodTruck.location.source,
            confidence: foodTruck.location.confidence,
            notes: foodTruck.location.notes,
            timestamp: foodTruck.location.lastUpdated || new Date()
          });
        }

        foodTruck.location = {
          type: 'Point',
          coordinates: [report.location.longitude, report.location.latitude],
          address: report.location.address,
          city: report.location.city,
          state: report.location.state,
          source: 'customer',
          confidence: 'medium',
          notes: `Customer report: ${report.location.notes}`,
          lastUpdated: new Date()
        };
      }

      await foodTruck.save();
      
      console.log(`✅ Customer reported ${report.truckName} location`);
      console.log(`   📍 ${report.location.address}`);
      console.log(`   💬 "${report.location.notes}"`);
      
    } catch (error) {
      console.error(`❌ Error processing customer report for ${report.truckName}:`, error.message);
    }
  }
  
  console.log('🎉 Customer reports simulation complete!');
}

// Main function
async function main() {
  try {
    console.log('🚀 Food Truck Social Media Tracking Demo');
    console.log('==========================================');
    
    // Run simulations
    await simulateSocialMediaTracking();
    console.log('');
    await simulateCustomerReports();
    
    console.log('\n📊 Summary:');
    console.log('- Social media tracking: Instagram, Facebook, Twitter updates');
    console.log('- Customer reports: User-submitted location sightings');
    console.log('- All updates include confidence levels and source tracking');
    console.log('- Location history preserved for each truck');
    
    console.log('\n🔗 Next steps:');
    console.log('- Check the owner dashboard to see location updates');
    console.log('- View customer app to see new location information');
    console.log('- Check location history for each truck');
    
  } catch (error) {
    console.error('❌ Error in main function:', error);
  } finally {
    mongoose.connection.close();
    console.log('\n👋 Disconnected from database');
  }
}

// Run the demo
if (require.main === module) {
  main();
}

module.exports = {
  simulateSocialMediaTracking,
  simulateCustomerReports
}; 
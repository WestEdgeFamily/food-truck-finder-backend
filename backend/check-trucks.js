const mongoose = require('mongoose');
const FoodTruck = require('./src/models/FoodTruck');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/foodtruck', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

async function checkTrucks() {
  try {
    const trucks = await FoodTruck.find({}, 'businessName name');
    console.log('Found food trucks:');
    trucks.forEach(truck => {
      console.log(`- businessName: "${truck.businessName}", name: "${truck.name}"`);
    });
  } catch (error) {
    console.error('Error:', error);
  } finally {
    mongoose.connection.close();
  }
}

checkTrucks(); 
const mongoose = require('mongoose');
const User = require('./models/User');
const Favorite = require('./models/Favorite');
const FoodTruck = require('./models/FoodTruck');

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/foodtruck';

async function debugDatabaseIssue() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB successfully!');
    console.log(`📍 Connected to: ${mongoose.connection.db.databaseName}`);
    console.log(`🔗 Connection state: ${mongoose.connection.readyState}`);

    // Check collections
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('\n📚 Available collections:');
    collections.forEach(col => {
      console.log(`  - ${col.name}`);
    });

    // Try to create a user manually
    console.log('\n🧪 Testing manual user creation...');
    const testUser = new User({
      _id: 'manual_test_user',
      name: 'Manual Test User',
      email: 'manual@test.com',
      password: 'test123',
      role: 'customer',
      createdAt: new Date()
    });

    const savedUser = await testUser.save();
    console.log(`✅ Manual user created: ${savedUser._id}`);

    // Try to create a favorite manually
    console.log('\n❤️ Testing manual favorite creation...');
    const testFavorite = new Favorite({
      userId: 'manual_test_user',
      truckId: '1'
    });

    const savedFavorite = await testFavorite.save();
    console.log(`✅ Manual favorite created: ${savedFavorite.userId} -> ${savedFavorite.truckId}`);

    // Check what's actually in the database now
    const allUsers = await User.find({});
    const allFavorites = await Favorite.find({});
    const allTrucks = await FoodTruck.find({});

    console.log(`\n📊 Database counts:`);
    console.log(`  Users: ${allUsers.length}`);
    console.log(`  Favorites: ${allFavorites.length}`);
    console.log(`  Food Trucks: ${allTrucks.length}`);

    console.log('\n👥 All users:');
    allUsers.forEach(user => {
      console.log(`  ${user._id} | ${user.name} | ${user.email} | ${user.role}`);
    });

    console.log('\n❤️ All favorites:');
    allFavorites.forEach(fav => {
      console.log(`  ${fav.userId} -> ${fav.truckId}`);
    });

    // Clean up test data
    await User.deleteOne({ _id: 'manual_test_user' });
    await Favorite.deleteOne({ userId: 'manual_test_user', truckId: '1' });
    console.log('\n🧹 Test data cleaned up');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Run the debug
debugDatabaseIssue(); 
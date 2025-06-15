const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Import models
const User = require('../src/models/User');

async function seedTestCustomer() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Create test customer account
    const testCustomer = {
      name: 'Test Customer',
      email: 'test@example.com',
      password: 'password123',
      phone: '(801) 555-0123',
      role: 'customer',
      preferences: {
        notifications: {
          pushEnabled: true,
          emailEnabled: true,
          favoriteUpdates: true,
          nearbyTrucks: true
        },
        location: {
          shareLocation: true,
          defaultRadius: 15,
          autoDetectLocation: true
        },
        display: {
          theme: 'auto',
          language: 'en',
          showDistance: true,
          showPrices: true
        }
      }
    };

    // Check if customer already exists
    let customer = await User.findOne({ email: testCustomer.email });
    
    if (!customer) {
      // Hash password
      const salt = await bcrypt.genSalt(10);
      testCustomer.password = await bcrypt.hash(testCustomer.password, salt);
      
      // Create customer
      customer = new User(testCustomer);
      await customer.save();
      console.log('Created test customer account');
    } else {
      console.log('Test customer account already exists');
    }

    console.log('\nTest Customer Login Credentials:');
    console.log('Email: test@example.com');
    console.log('Password: password123');

  } catch (error) {
    console.error('Error seeding test customer:', error);
  } finally {
    mongoose.connection.close();
    console.log('\nDatabase connection closed');
  }
}

// Run the seeding script
if (require.main === module) {
  seedTestCustomer();
}

module.exports = { seedTestCustomer }; 
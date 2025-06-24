const mongoose = require('mongoose');
const FoodTruck = require('./models/FoodTruck');

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/foodtruck';

async function updateFoodTrucksWithEmails() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB successfully!');

    // Email mappings for existing food trucks
    const emailUpdates = [
      {
        name: 'Cupbop Korean BBQ',
        email: 'info@cupbop.com',
        website: 'www.cupbop.com'
      },
      {
        name: 'The Pie Pizzeria',
        email: 'orders@thepie.com',
        website: 'www.thepie.com'
      },
      {
        name: 'Red Iguana Mobile',
        email: 'mobile@rediguana.com',
        website: 'www.rediguana.com'
      },
      {
        name: 'Crown Burgers Mobile',
        email: 'contact@crownburgers.com',
        website: 'www.crownburgers.com'
      },
      {
        name: 'Sill-Ice Cream Truck',
        email: 'hello@sillicecream.com',
        website: 'www.sillicecream.com'
      }
    ];

    console.log('📧 Updating food trucks with email addresses...');

    for (const update of emailUpdates) {
      const result = await FoodTruck.updateOne(
        { name: update.name },
        { 
          $set: { 
            email: update.email,
            website: update.website
          } 
        }
      );
      
      if (result.matchedCount > 0) {
        console.log(`✅ Updated ${update.name} with email: ${update.email}`);
      } else {
        console.log(`⚠️ Food truck not found: ${update.name}`);
      }
    }

    // Also update any user-created food trucks that don't have emails
    const trucksWithoutEmails = await FoodTruck.find({
      $or: [
        { email: { $exists: false } },
        { email: null },
        { email: '' }
      ]
    });

    console.log(`📝 Found ${trucksWithoutEmails.length} trucks without email addresses`);

    for (const truck of trucksWithoutEmails) {
      // Generate a basic email for user-created trucks
      const emailDomain = truck.name.toLowerCase()
        .replace(/[^a-z0-9]/g, '')
        .substring(0, 10);
      
      const generatedEmail = `contact@${emailDomain}.com`;
      const generatedWebsite = `www.${emailDomain}.com`;

      await FoodTruck.updateOne(
        { _id: truck._id },
        { 
          $set: { 
            email: generatedEmail,
            website: generatedWebsite
          } 
        }
      );

      console.log(`📧 Added email to ${truck.name}: ${generatedEmail}`);
    }

    console.log('🎉 Email update complete!');

    // Display current food trucks with emails
    const allTrucks = await FoodTruck.find({}, 'name email website');
    console.log('\n📋 Current food trucks with contact info:');
    allTrucks.forEach(truck => {
      console.log(`  ${truck.name}: ${truck.email || 'No email'} | ${truck.website || 'No website'}`);
    });

  } catch (error) {
    console.error('❌ Error updating emails:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Run the update
updateFoodTrucksWithEmails(); 
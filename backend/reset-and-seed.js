const mongoose = require('mongoose');
const FoodTruck = require('./src/models/FoodTruck');
const User = require('./src/models/User');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/foodtruck', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const sampleFoodTrucks = [
  {
    businessName: "Taco Fiesta",
    phoneNumber: "555-0101",
    description: "Authentic Mexican street tacos and burritos",
    location: {
      type: "Point",
      coordinates: [-73.935242, 40.730610],
      city: "New York",
      state: "NY"
    },
    foodTypes: ["Mexican", "Latin", "Street Food"],
    businessHours: [
      { day: "Monday", open: "11:00", close: "20:00" },
      { day: "Tuesday", open: "11:00", close: "20:00" },
      { day: "Wednesday", open: "11:00", close: "20:00" },
      { day: "Thursday", open: "11:00", close: "21:00" },
      { day: "Friday", open: "11:00", close: "22:00" },
      { day: "Saturday", open: "12:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    isActive: true,
    menu: [
      { name: "Street Tacos", description: "3 authentic corn tortilla tacos", price: 9.99, category: "Main Course" },
      { name: "Burrito Supreme", description: "Large burrito with all the fixings", price: 11.99, category: "Main Course" }
    ]
  },
  {
    businessName: "Seoul Food",
    phoneNumber: "555-0102",
    description: "Korean fusion BBQ and rice bowls",
    location: {
      type: "Point",
      coordinates: [-118.243683, 34.052235],
      city: "Los Angeles",
      state: "CA"
    },
    foodTypes: ["Korean", "BBQ", "Fusion", "Asian"],
    businessHours: [
      { day: "Monday", open: "11:30", close: "21:00" },
      { day: "Tuesday", open: "11:30", close: "21:00" },
      { day: "Wednesday", open: "11:30", close: "21:00" },
      { day: "Thursday", open: "11:30", close: "21:00" },
      { day: "Friday", open: "11:30", close: "22:00" },
      { day: "Saturday", open: "12:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "21:00" }
    ],
    isActive: true,
    menu: [
      { name: "Bulgogi Bowl", description: "Marinated beef with rice", price: 13.99, category: "Main Course" },
      { name: "Kimchi Fries", description: "Loaded fries with kimchi and sauce", price: 8.99, category: "Sides" }
    ]
  },
  {
    businessName: "Smokin' BBQ",
    phoneNumber: "555-0103",
    description: "Texas-style BBQ with all the fixings",
    location: {
      type: "Point",
      coordinates: [-97.743061, 30.267153],
      city: "Austin",
      state: "TX"
    },
    foodTypes: ["BBQ", "American", "Southern"],
    businessHours: [
      { day: "Monday", open: "11:00", close: "19:00" },
      { day: "Tuesday", open: "11:00", close: "19:00" },
      { day: "Wednesday", open: "11:00", close: "19:00" },
      { day: "Thursday", open: "11:00", close: "19:00" },
      { day: "Friday", open: "11:00", close: "21:00" },
      { day: "Saturday", open: "11:00", close: "21:00" },
      { day: "Sunday", open: "11:00", close: "19:00" }
    ],
    isActive: true,
    menu: [
      { name: "Brisket Plate", description: "Smoked brisket with two sides", price: 18.99, category: "Main Course" },
      { name: "Pulled Pork Sandwich", description: "Classic pulled pork on brioche", price: 12.99, category: "Main Course" }
    ]
  },
  {
    businessName: "Pizza on Wheels",
    phoneNumber: "555-0104",
    description: "Wood-fired Neapolitan pizza made fresh",
    location: {
      type: "Point",
      coordinates: [-87.629798, 41.878113],
      city: "Chicago",
      state: "IL"
    },
    foodTypes: ["Italian", "Pizza", "Mediterranean"],
    businessHours: [
      { day: "Monday", open: "12:00", close: "20:00" },
      { day: "Tuesday", open: "12:00", close: "20:00" },
      { day: "Wednesday", open: "12:00", close: "20:00" },
      { day: "Thursday", open: "12:00", close: "20:00" },
      { day: "Friday", open: "12:00", close: "22:00" },
      { day: "Saturday", open: "12:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    isActive: true,
    menu: [
      { name: "Margherita Pizza", description: "Classic tomato, mozzarella, basil", price: 14.99, category: "Main Course" },
      { name: "Pepperoni Pizza", description: "Spicy pepperoni with mozzarella", price: 16.99, category: "Main Course" }
    ]
  },
  {
    businessName: "Sushi Express",
    phoneNumber: "555-0105",
    description: "Fresh sushi rolls and Japanese favorites",
    location: {
      type: "Point",
      coordinates: [-122.419416, 37.774929],
      city: "San Francisco",
      state: "CA"
    },
    foodTypes: ["Japanese", "Sushi", "Asian"],
    businessHours: [
      { day: "Monday", open: "11:30", close: "21:00" },
      { day: "Tuesday", open: "11:30", close: "21:00" },
      { day: "Wednesday", open: "11:30", close: "21:00" },
      { day: "Thursday", open: "11:30", close: "21:00" },
      { day: "Friday", open: "11:30", close: "22:00" },
      { day: "Saturday", open: "12:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "21:00" }
    ],
    isActive: true,
    menu: [
      { name: "California Roll", description: "Crab, avocado, cucumber", price: 8.99, category: "Main Course" },
      { name: "Spicy Tuna Roll", description: "Fresh tuna with spicy sauce", price: 10.99, category: "Main Course" }
    ]
  }
];

async function resetAndSeed() {
  try {
    console.log('🗑️  Clearing existing data...');
    await FoodTruck.deleteMany({});
    await User.deleteMany({});
    
    console.log('🌱 Seeding fresh data...');
    
    // Create owner accounts for each food truck
    for (let i = 0; i < sampleFoodTrucks.length; i++) {
      console.log(`Creating ${sampleFoodTrucks[i].businessName}...`);
      
      // Create owner account
      const hashedPassword = await bcrypt.hash('password123', 10);
      const owner = await User.create({
        name: `${sampleFoodTrucks[i].businessName} Owner`,
        email: `owner${i + 1}@example.com`,
        password: hashedPassword,
        role: 'owner',
        businessName: sampleFoodTrucks[i].businessName,
        phoneNumber: sampleFoodTrucks[i].phoneNumber
      });

      // Create food truck with owner reference and set name = businessName
      const foodTruckData = {
        ...sampleFoodTrucks[i],
        name: sampleFoodTrucks[i].businessName, // Set name field too
        owner: owner._id
      };
      await FoodTruck.create(foodTruckData);
      console.log(`✅ Created ${sampleFoodTrucks[i].businessName}`);
    }

    console.log('🎉 Database reset and seeded successfully!');
    
    // Verify data
    const count = await FoodTruck.countDocuments();
    console.log(`📊 Total food trucks in database: ${count}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    mongoose.connection.close();
  }
}

resetAndSeed(); 
const mongoose = require('mongoose');
const FoodTruck = require('./models/FoodTruck');
const User = require('./models/User');
const bcrypt = require('bcryptjs');
const config = require('./config/config');

const sampleFoodTrucks = [
  {
    businessName: "Taco Fiesta",
    phoneNumber: "555-0101",
    description: "Authentic Mexican street tacos and burritos",
    location: {
      type: "Point",
      coordinates: [-73.935242, 40.730610], // NYC coordinates
      city: "New York",
      state: "NY"
    },
    foodTypes: ["Mexican", "Latin", "Street Food"],
    operatingHours: [
      { day: "Monday", open: "11:00", close: "20:00" },
      { day: "Tuesday", open: "11:00", close: "20:00" },
      { day: "Wednesday", open: "11:00", close: "20:00" },
      { day: "Thursday", open: "11:00", close: "21:00" },
      { day: "Friday", open: "11:00", close: "22:00" },
      { day: "Saturday", open: "12:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    isCurrentlyOpen: true,
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
      coordinates: [-118.243683, 34.052235], // LA coordinates
      city: "Los Angeles",
      state: "CA"
    },
    foodTypes: ["Korean", "BBQ", "Fusion", "Asian"],
    operatingHours: [
      { day: "Monday", open: "11:30", close: "21:00" },
      { day: "Tuesday", open: "11:30", close: "21:00" },
      { day: "Wednesday", open: "11:30", close: "21:00" },
      { day: "Thursday", open: "11:30", close: "21:00" },
      { day: "Friday", open: "11:30", close: "22:00" },
      { day: "Saturday", open: "12:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "21:00" }
    ],
    isCurrentlyOpen: true,
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
      coordinates: [-97.743061, 30.267153], // Austin coordinates
      city: "Austin",
      state: "TX"
    },
    foodTypes: ["BBQ", "American", "Southern"],
    operatingHours: [
      { day: "Monday", open: "11:00", close: "19:00" },
      { day: "Tuesday", open: "11:00", close: "19:00" },
      { day: "Wednesday", open: "11:00", close: "19:00" },
      { day: "Thursday", open: "11:00", close: "19:00" },
      { day: "Friday", open: "11:00", close: "21:00" },
      { day: "Saturday", open: "11:00", close: "21:00" },
      { day: "Sunday", open: "11:00", close: "19:00" }
    ],
    isCurrentlyOpen: true,
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
      coordinates: [-87.629798, 41.878113], // Chicago coordinates
      city: "Chicago",
      state: "IL"
    },
    foodTypes: ["Italian", "Pizza", "Mediterranean"],
    operatingHours: [
      { day: "Monday", open: "12:00", close: "20:00" },
      { day: "Tuesday", open: "12:00", close: "20:00" },
      { day: "Wednesday", open: "12:00", close: "20:00" },
      { day: "Thursday", open: "12:00", close: "20:00" },
      { day: "Friday", open: "12:00", close: "22:00" },
      { day: "Saturday", open: "12:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    isCurrentlyOpen: true,
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
      coordinates: [-122.419416, 37.774929], // San Francisco coordinates
      city: "San Francisco",
      state: "CA"
    },
    foodTypes: ["Japanese", "Sushi", "Asian"],
    operatingHours: [
      { day: "Monday", open: "11:30", close: "21:00" },
      { day: "Tuesday", open: "11:30", close: "21:00" },
      { day: "Wednesday", open: "11:30", close: "21:00" },
      { day: "Thursday", open: "11:30", close: "21:00" },
      { day: "Friday", open: "11:30", close: "22:00" },
      { day: "Saturday", open: "12:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "21:00" }
    ],
    isCurrentlyOpen: true,
    menu: [
      { name: "California Roll", description: "Crab, avocado, cucumber", price: 8.99, category: "Main Course" },
      { name: "Spicy Tuna Roll", description: "Fresh tuna with spicy sauce", price: 10.99, category: "Main Course" }
    ]
  }
];

async function seedData() {
  try {
    // Connect to MongoDB
    await mongoose.connect(config.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('Connected to MongoDB for seeding...');

    // Create owner accounts for each food truck
    for (let i = 0; i < sampleFoodTrucks.length; i++) {
      // Create owner account
      const hashedPassword = await bcrypt.hash('password123', 10);
      const owner = await User.create({
        name: `Owner ${i + 1}`,
        email: `owner${i + 1}@example.com`,
        password: hashedPassword,
        role: 'owner',
        businessName: sampleFoodTrucks[i].businessName,
        phoneNumber: sampleFoodTrucks[i].phoneNumber
      });

      // Create food truck with owner reference
      const foodTruckData = {
        ...sampleFoodTrucks[i],
        owner: owner._id
      };
      await FoodTruck.create(foodTruckData);
    }

    console.log('Sample data seeded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

// Run the seeding function
seedData(); 
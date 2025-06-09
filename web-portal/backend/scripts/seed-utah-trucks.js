const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Import models
const User = require('../src/models/User');
const FoodTruck = require('../src/models/FoodTruck');

const UTAH_FOOD_TRUCKS = [
  {
    name: "Taco Cartel",
    businessName: "Taco Cartel LLC",
    phoneNumber: "(801) 555-0101",
    description: "Authentic Mexican street tacos with fresh ingredients and bold flavors",
    cuisineType: "Mexican",
    location: {
      address: "Downtown Salt Lake City",
      city: "Salt Lake City",
      state: "Utah",
      coordinates: [-111.8910, 40.7608]
    },
    businessHours: [
      { day: "Monday", open: "11:00", close: "21:00" },
      { day: "Tuesday", open: "11:00", close: "21:00" },
      { day: "Wednesday", open: "11:00", close: "21:00" },
      { day: "Thursday", open: "11:00", close: "21:00" },
      { day: "Friday", open: "11:00", close: "22:00" },
      { day: "Saturday", open: "10:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    menu: [
      { name: "Street Tacos", description: "Authentic corn tortilla tacos with your choice of meat", price: 3.50, category: "Main Course" },
      { name: "Burrito Bowl", description: "Rice, beans, meat, and fresh toppings", price: 12.99, category: "Main Course" },
      { name: "Quesadilla", description: "Cheese and meat grilled to perfection", price: 8.99, category: "Main Course" },
      { name: "Chips & Guac", description: "Fresh tortilla chips with house-made guacamole", price: 5.99, category: "Appetizers" }
    ],
    isActive: true
  },
  {
    name: "Waffle Love",
    businessName: "Waffle Love Utah LLC",
    phoneNumber: "(801) 555-0102",
    description: "Belgian waffles with gourmet toppings and sweet treats",
    cuisineType: "Desserts",
    location: {
      address: "Sugar House District",
      city: "Salt Lake City",
      state: "Utah",
      coordinates: [-111.8693, 40.7210]
    },
    businessHours: [
      { day: "Monday", open: "08:00", close: "20:00" },
      { day: "Tuesday", open: "08:00", close: "20:00" },
      { day: "Wednesday", open: "08:00", close: "20:00" },
      { day: "Thursday", open: "08:00", close: "20:00" },
      { day: "Friday", open: "08:00", close: "21:00" },
      { day: "Saturday", open: "08:00", close: "21:00" },
      { day: "Sunday", open: "09:00", close: "19:00" }
    ],
    menu: [
      { name: "Original Waffle", description: "Belgian waffle with whipped cream and strawberries", price: 8.99, category: "Desserts" },
      { name: "Nutella Waffle", description: "Warm waffle with Nutella and banana", price: 10.99, category: "Desserts" },
      { name: "Chicken & Waffle", description: "Crispy chicken with maple syrup waffle", price: 14.99, category: "Main Course" },
      { name: "Ice Cream Waffle", description: "Waffle served with premium ice cream", price: 9.99, category: "Desserts" }
    ],
    isActive: true
  },
  {
    name: "Cupbop",
    businessName: "Cupbop Korean BBQ",
    phoneNumber: "(801) 555-0103",
    description: "Korean BBQ bowls served in eco-friendly cups",
    cuisineType: "Korean",
    location: {
      address: "University of Utah Campus",
      city: "Salt Lake City",
      state: "Utah",
      coordinates: [-111.8449, 40.7649]
    },
    businessHours: [
      { day: "Monday", open: "11:00", close: "21:00" },
      { day: "Tuesday", open: "11:00", close: "21:00" },
      { day: "Wednesday", open: "11:00", close: "21:00" },
      { day: "Thursday", open: "11:00", close: "21:00" },
      { day: "Friday", open: "11:00", close: "22:00" },
      { day: "Saturday", open: "11:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    menu: [
      { name: "BBQ Beef Cupbop", description: "Korean BBQ beef over rice with vegetables", price: 11.99, category: "Main Course" },
      { name: "Spicy Pork Cupbop", description: "Marinated spicy pork with steamed rice", price: 10.99, category: "Main Course" },
      { name: "Chicken Cupbop", description: "Grilled chicken with Korean sauce and rice", price: 10.99, category: "Main Course" },
      { name: "Mandu (Dumplings)", description: "Korean-style dumplings with dipping sauce", price: 6.99, category: "Appetizers" }
    ],
    isActive: true
  },
  {
    name: "Chow Truck",
    businessName: "Chow Truck Asian Fusion",
    phoneNumber: "(801) 555-0104",
    description: "Asian fusion cuisine with fresh ingredients and bold flavors",
    cuisineType: "Asian",
    location: {
      address: "Trolley Square",
      city: "Salt Lake City",
      state: "Utah",
      coordinates: [-111.8785, 40.7505]
    },
    businessHours: [
      { day: "Monday", open: "11:30", close: "20:00" },
      { day: "Tuesday", open: "11:30", close: "20:00" },
      { day: "Wednesday", open: "11:30", close: "20:00" },
      { day: "Thursday", open: "11:30", close: "20:00" },
      { day: "Friday", open: "11:30", close: "21:00" },
      { day: "Saturday", open: "11:30", close: "21:00" },
      { day: "Sunday", open: "Closed", close: "Closed" }
    ],
    menu: [
      { name: "Pad Thai", description: "Traditional Thai noodles with tamarind sauce", price: 12.99, category: "Main Course" },
      { name: "Asian Fusion Bowl", description: "Rice bowl with choice of protein and Asian vegetables", price: 11.99, category: "Main Course" },
      { name: "Spring Rolls", description: "Fresh vegetable spring rolls with peanut sauce", price: 7.99, category: "Appetizers" },
      { name: "Thai Curry", description: "Coconut curry with vegetables and your choice of protein", price: 13.99, category: "Main Course" }
    ],
    isActive: true
  },
  {
    name: "Blake's Gourmet",
    businessName: "Blake's Gourmet Food Truck",
    phoneNumber: "(801) 555-0105",
    description: "Gourmet burgers and comfort food made with quality ingredients",
    cuisineType: "American",
    location: {
      address: "Liberty Park Area",
      city: "Salt Lake City",
      state: "Utah",
      coordinates: [-111.8766, 40.7424]
    },
    businessHours: [
      { day: "Monday", open: "11:00", close: "21:00" },
      { day: "Tuesday", open: "11:00", close: "21:00" },
      { day: "Wednesday", open: "11:00", close: "21:00" },
      { day: "Thursday", open: "11:00", close: "21:00" },
      { day: "Friday", open: "11:00", close: "22:00" },
      { day: "Saturday", open: "11:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    menu: [
      { name: "Blake's Classic Burger", description: "Beef patty with lettuce, tomato, and special sauce", price: 12.99, category: "Main Course" },
      { name: "BBQ Bacon Burger", description: "Burger with BBQ sauce, bacon, and onion rings", price: 14.99, category: "Main Course" },
      { name: "Sweet Potato Fries", description: "Crispy sweet potato fries with chipotle aioli", price: 6.99, category: "Sides" },
      { name: "Craft Beer Float", description: "Local beer with vanilla ice cream", price: 7.99, category: "Drinks" }
    ],
    isActive: true
  },
  {
    name: "Greek N Go",
    businessName: "Greek N Go Food Truck",
    phoneNumber: "(801) 555-0106",
    description: "Authentic Greek food including gyros, souvlaki, and Mediterranean favorites",
    cuisineType: "Mediterranean",
    location: {
      address: "Provo Downtown",
      city: "Provo",
      state: "Utah",
      coordinates: [-111.6585, 40.2338]
    },
    businessHours: [
      { day: "Monday", open: "11:00", close: "20:00" },
      { day: "Tuesday", open: "11:00", close: "20:00" },
      { day: "Wednesday", open: "11:00", close: "20:00" },
      { day: "Thursday", open: "11:00", close: "20:00" },
      { day: "Friday", open: "11:00", close: "21:00" },
      { day: "Saturday", open: "11:00", close: "21:00" },
      { day: "Sunday", open: "Closed", close: "Closed" }
    ],
    menu: [
      { name: "Chicken Gyro", description: "Grilled chicken with tzatziki sauce in pita bread", price: 10.99, category: "Main Course" },
      { name: "Lamb Souvlaki", description: "Marinated lamb skewers with Greek seasoning", price: 13.99, category: "Main Course" },
      { name: "Greek Salad", description: "Fresh salad with feta, olives, and Greek dressing", price: 8.99, category: "Sides" },
      { name: "Baklava", description: "Traditional Greek pastry with honey and nuts", price: 4.99, category: "Desserts" }
    ],
    isActive: true
  },
  {
    name: "Cravings Grilled Cheese",
    businessName: "Cravings Grilled Cheese Truck",
    phoneNumber: "(801) 555-0107",
    description: "Gourmet grilled cheese sandwiches with creative combinations",
    cuisineType: "American",
    location: {
      address: "Pleasant Grove Center",
      city: "Pleasant Grove",
      state: "Utah",
      coordinates: [-111.7385, 40.3641]
    },
    businessHours: [
      { day: "Monday", open: "11:00", close: "20:00" },
      { day: "Tuesday", open: "11:00", close: "20:00" },
      { day: "Wednesday", open: "11:00", close: "20:00" },
      { day: "Thursday", open: "11:00", close: "20:00" },
      { day: "Friday", open: "11:00", close: "21:00" },
      { day: "Saturday", open: "11:00", close: "21:00" },
      { day: "Sunday", open: "12:00", close: "19:00" }
    ],
    menu: [
      { name: "Classic Grilled Cheese", description: "Melted cheddar on artisan bread", price: 7.99, category: "Main Course" },
      { name: "BBQ Pulled Pork Melt", description: "Pulled pork with cheese and BBQ sauce", price: 11.99, category: "Main Course" },
      { name: "Caprese Melt", description: "Mozzarella, tomato, and basil grilled sandwich", price: 9.99, category: "Main Course" },
      { name: "Tomato Soup", description: "Creamy tomato soup perfect for dipping", price: 5.99, category: "Sides" }
    ],
    isActive: true
  },
  {
    name: "Rocky Mountain Burger Bus",
    businessName: "Rocky Mountain Burger Bus LLC",
    phoneNumber: "(801) 555-0108",
    description: "Utah's premier local burger caterer with grass-fed beef",
    cuisineType: "American",
    location: {
      address: "Various Locations",
      city: "Salt Lake City",
      state: "Utah",
      coordinates: [-111.8910, 40.7608]
    },
    businessHours: [
      { day: "Monday", open: "11:00", close: "21:00" },
      { day: "Tuesday", open: "11:00", close: "21:00" },
      { day: "Wednesday", open: "11:00", close: "21:00" },
      { day: "Thursday", open: "11:00", close: "21:00" },
      { day: "Friday", open: "11:00", close: "22:00" },
      { day: "Saturday", open: "11:00", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    menu: [
      { name: "Rocky Mountain Burger", description: "Grass-fed beef with local cheese and house sauce", price: 13.99, category: "Main Course" },
      { name: "Bison Burger", description: "Local bison patty with wild mushrooms", price: 16.99, category: "Main Course" },
      { name: "Truffle Fries", description: "Hand-cut fries with truffle oil and parmesan", price: 8.99, category: "Sides" },
      { name: "Local Beer", description: "Rotating selection of Utah craft beers", price: 5.99, category: "Drinks" }
    ],
    isActive: true
  },
  {
    name: "The Angry Korean",
    businessName: "The Angry Korean Food Truck",
    phoneNumber: "(801) 555-0109",
    description: "Spicy Korean street food and fusion dishes",
    cuisineType: "Korean",
    location: {
      address: "West Valley City",
      city: "West Valley City",
      state: "Utah",
      coordinates: [-112.0011, 40.6916]
    },
    businessHours: [
      { day: "Monday", open: "11:30", close: "21:00" },
      { day: "Tuesday", open: "11:30", close: "21:00" },
      { day: "Wednesday", open: "11:30", close: "21:00" },
      { day: "Thursday", open: "11:30", close: "21:00" },
      { day: "Friday", open: "11:30", close: "22:00" },
      { day: "Saturday", open: "11:30", close: "22:00" },
      { day: "Sunday", open: "12:00", close: "20:00" }
    ],
    menu: [
      { name: "Angry Chicken", description: "Spicy Korean fried chicken with gochujang sauce", price: 12.99, category: "Main Course" },
      { name: "Kimchi Fried Rice", description: "Fried rice with fermented vegetables and pork", price: 10.99, category: "Main Course" },
      { name: "Korean Tacos", description: "Fusion tacos with Korean BBQ and kimchi", price: 3.99, category: "Main Course" },
      { name: "Miso Soup", description: "Traditional soybean soup with tofu", price: 4.99, category: "Sides" }
    ],
    isActive: true
  },
  {
    name: "Havana Eats",
    businessName: "Havana Eats Cuban Kitchen",
    phoneNumber: "(801) 555-0110",
    description: "Authentic Cuban cuisine with traditional flavors and recipes",
    cuisineType: "Cuban",
    location: {
      address: "Murray City Center",
      city: "Murray",
      state: "Utah",
      coordinates: [-111.8879, 40.6669]
    },
    businessHours: [
      { day: "Monday", open: "11:00", close: "20:00" },
      { day: "Tuesday", open: "11:00", close: "20:00" },
      { day: "Wednesday", open: "11:00", close: "20:00" },
      { day: "Thursday", open: "11:00", close: "20:00" },
      { day: "Friday", open: "11:00", close: "21:00" },
      { day: "Saturday", open: "11:00", close: "21:00" },
      { day: "Sunday", open: "12:00", close: "19:00" }
    ],
    menu: [
      { name: "Cubano Sandwich", description: "Traditional Cuban sandwich with pork, ham, and pickles", price: 11.99, category: "Main Course" },
      { name: "Mojo Pork", description: "Slow-cooked pork with citrus mojo sauce", price: 13.99, category: "Main Course" },
      { name: "Black Beans & Rice", description: "Traditional Cuban black beans with yellow rice", price: 7.99, category: "Sides" },
      { name: "Flan", description: "Cuban custard dessert with caramel sauce", price: 5.99, category: "Desserts" }
    ],
    isActive: true
  }
];

async function seedDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing data
    console.log('Clearing existing food trucks and users...');
    await FoodTruck.deleteMany({});
    await User.deleteMany({ role: 'owner' }); // Only delete owner accounts, keep admin accounts

    // Create owner accounts for each truck
    console.log('Creating food truck owners and trucks...');
    
    for (let i = 0; i < UTAH_FOOD_TRUCKS.length; i++) {
      const truckData = UTAH_FOOD_TRUCKS[i];
      
      // Create owner account
      const ownerEmail = `${truckData.name.toLowerCase().replace(/[^a-z0-9]/g, '')}@utah-trucks.com`;
      const hashedPassword = await bcrypt.hash('foodtruck2024', 12);
      
      const owner = new User({
        name: `${truckData.name} Owner`,
        email: ownerEmail,
        password: hashedPassword,
        role: 'owner'
      });
      
      await owner.save();
      console.log(`Created owner: ${ownerEmail}`);
      
      // Create food truck
      const truck = new FoodTruck({
        ...truckData,
        owner: owner._id,
        trackingPreferences: {
          allowCustomerReports: true,
          requireLocationVerification: false,
          autoPostToSocial: true
        },
        socialMedia: {
          instagram: {
            username: `@${truckData.name.toLowerCase().replace(/[^a-z0-9]/g, '')}utah`,
            autoTrack: true
          },
          facebook: {
            pageName: `${truckData.name} Utah`,
            autoTrack: true
          }
        }
      });
      
      await truck.save();
      console.log(`Created truck: ${truckData.name}`);
    }

    console.log(`\n🎉 Successfully seeded ${UTAH_FOOD_TRUCKS.length} Utah food trucks!`);
    console.log('\nOwner login credentials:');
    console.log('Password for all: foodtruck2024');
    console.log('\nExample emails:');
    UTAH_FOOD_TRUCKS.slice(0, 3).forEach(truck => {
      console.log(`- ${truck.name.toLowerCase().replace(/[^a-z0-9]/g, '')}@utah-trucks.com`);
    });

  } catch (error) {
    console.error('Error seeding database:', error);
  } finally {
    mongoose.connection.close();
    console.log('\nDatabase connection closed');
  }
}

// Run the seeding script
if (require.main === module) {
  seedDatabase();
}

module.exports = { seedDatabase, UTAH_FOOD_TRUCKS };
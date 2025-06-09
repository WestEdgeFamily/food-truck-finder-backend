const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Import models
const User = require('../src/models/User');
const Event = require('../src/models/Event');
const FoodTruck = require('../src/models/FoodTruck');

const UTAH_EVENTS = [
  {
    name: "Food Truck Thursdays at Gallivan Center",
    description: "Weekly food truck gathering featuring the best local food trucks in downtown Salt Lake City. Live music, family-friendly atmosphere, and great food!",
    eventType: "market",
    location: {
      address: "239 S Main St",
      city: "Salt Lake City",
      state: "Utah",
      zipCode: "84111",
      venue: "Gallivan Center",
      coordinates: [-111.8889, 40.7617]
    },
    startDate: new Date('2025-06-12'),
    endDate: new Date('2025-06-12'),
    startTime: "11:00",
    endTime: "21:00",
    organizer: {
      name: "Gallivan Center",
      email: "events@gallivancenter.org",
      phone: "(801) 532-0459",
      website: "https://www.gallivancenter.org"
    },
    maxTrucks: 15,
    registrationDeadline: new Date('2025-06-10'),
    entryFee: 0,
    expectedAttendance: 2000,
    amenities: ["electricity", "water", "waste_disposal", "security", "parking", "restrooms", "seating", "stage", "music"],
    requirements: ["Food handler's permit required", "Insurance certificate needed", "Current business license"],
    tags: ["weekly", "downtown", "family-friendly", "music"],
    isPublic: true,
    isActive: true,
    weatherContingency: "Event moved indoors to Gallivan Center in case of severe weather",
    socialMedia: {
      website: "https://www.gallivancenter.org",
      facebook: "https://facebook.com/gallivancenter",
      instagram: "@gallivancenterslc"
    }
  },
  {
    name: "Granary Row Food Truck Festival",
    description: "Multi-day food truck festival in the trendy Granary District with local breweries, artisan vendors, and live entertainment.",
    eventType: "festival",
    location: {
      address: "600 W 100 S",
      city: "Salt Lake City",
      state: "Utah",
      zipCode: "84101",
      venue: "Granary District",
      coordinates: [-111.9050, 40.7648]
    },
    startDate: new Date('2025-07-04'),
    endDate: new Date('2025-07-06'),
    startTime: "10:00",
    endTime: "22:00",
    organizer: {
      name: "Granary Row Events",
      email: "info@granaryrow.com",
      phone: "(801) 555-0123",
      website: "https://www.granaryrow.com"
    },
    maxTrucks: 25,
    registrationDeadline: new Date('2025-06-25'),
    entryFee: 150,
    expectedAttendance: 8000,
    amenities: ["electricity", "water", "waste_disposal", "security", "parking", "wifi", "restrooms", "seating", "stage", "music"],
    requirements: ["Food handler's permit required", "Insurance certificate needed", "Special event permit", "$1M liability insurance"],
    tags: ["festival", "holiday", "multi-day", "brewery", "artisan"],
    isPublic: true,
    isActive: true,
    weatherContingency: "Covered areas available for vendors in case of rain",
    socialMedia: {
      website: "https://www.granaryrow.com",
      facebook: "https://facebook.com/granaryrowslc",
      instagram: "@granaryrowslc",
      twitter: "@granaryrowslc"
    }
  },
  {
    name: "Utah State Fair Food Court",
    description: "Join the iconic Utah State Fair as a food vendor! Serve thousands of fairgoers during this beloved annual tradition.",
    eventType: "festival",
    location: {
      address: "155 N 1000 W",
      city: "Salt Lake City",
      state: "Utah",
      zipCode: "84116",
      venue: "Utah State Fairpark",
      coordinates: [-111.9287, 40.7755]
    },
    startDate: new Date('2025-09-05'),
    endDate: new Date('2025-09-15'),
    startTime: "10:00",
    endTime: "23:00",
    organizer: {
      name: "Utah State Fair",
      email: "vendors@utahstatefair.com",
      phone: "(801) 538-8400",
      website: "https://www.utahstatefair.com"
    },
    maxTrucks: 30,
    registrationDeadline: new Date('2025-08-01'),
    entryFee: 500,
    expectedAttendance: 300000,
    amenities: ["electricity", "water", "waste_disposal", "security", "parking", "restrooms"],
    requirements: ["Food handler's permit required", "Insurance certificate needed", "State fair vendor application", "Health department approval"],
    tags: ["state-fair", "multi-day", "traditional", "large-scale"],
    isPublic: true,
    isActive: true,
    weatherContingency: "Some covered areas available",
    socialMedia: {
      website: "https://www.utahstatefair.com",
      facebook: "https://facebook.com/utahstatefair",
      instagram: "@utahstatefair"
    }
  },
  {
    name: "University of Utah Game Day",
    description: "Food trucks serving hungry fans before and after the big game! High traffic location with thousands of students and alumni.",
    eventType: "sports",
    location: {
      address: "451 S 1400 E",
      city: "Salt Lake City",
      state: "Utah",
      zipCode: "84112",
      venue: "Rice-Eccles Stadium",
      coordinates: [-111.8508, 40.7581]
    },
    startDate: new Date('2025-09-20'),
    endDate: new Date('2025-09-20'),
    startTime: "09:00",
    endTime: "17:00",
    organizer: {
      name: "University of Utah Athletics",
      email: "gameday@athletics.utah.edu",
      phone: "(801) 581-8849",
      website: "https://utahutes.com"
    },
    maxTrucks: 12,
    registrationDeadline: new Date('2025-09-15'),
    entryFee: 100,
    expectedAttendance: 15000,
    amenities: ["electricity", "security", "parking", "restrooms"],
    requirements: ["Food handler's permit required", "Insurance certificate needed", "University vendor approval"],
    tags: ["sports", "university", "game-day", "high-traffic"],
    isPublic: true,
    isActive: true,
    weatherContingency: "Event continues rain or shine",
    socialMedia: {
      website: "https://utahutes.com",
      facebook: "https://facebook.com/utahutes",
      instagram: "@utahutes",
      twitter: "@utahutes"
    }
  },
  {
    name: "Park City Summer Concert Series",
    description: "Weekly summer concerts in beautiful Park City with food trucks providing dinner options for concert-goers.",
    eventType: "concert",
    location: {
      address: "1255 Park Ave",
      city: "Park City",
      state: "Utah",
      zipCode: "84060",
      venue: "Park City Mountain Resort",
      coordinates: [-111.4980, 40.6516]
    },
    startDate: new Date('2025-07-15'),
    endDate: new Date('2025-07-15'),
    startTime: "17:00",
    endTime: "22:00",
    organizer: {
      name: "Park City Events",
      email: "concerts@parkcity.org",
      phone: "(435) 615-5000",
      website: "https://www.parkcity.org"
    },
    maxTrucks: 8,
    registrationDeadline: new Date('2025-07-10'),
    entryFee: 75,
    expectedAttendance: 3000,
    amenities: ["electricity", "water", "security", "parking", "restrooms", "stage", "music"],
    requirements: ["Food handler's permit required", "Insurance certificate needed", "Summit County permit"],
    tags: ["concert", "weekly", "summer", "mountain", "tourist"],
    isPublic: true,
    isActive: true,
    weatherContingency: "Indoor venue available if needed",
    socialMedia: {
      website: "https://www.parkcity.org",
      facebook: "https://facebook.com/parkcityutah",
      instagram: "@visitparkcity"
    }
  },
  {
    name: "Provo Farmers Market",
    description: "Weekly farmers market featuring local produce, artisan goods, and food trucks in downtown Provo.",
    eventType: "market",
    location: {
      address: "88 W Center St",
      city: "Provo",
      state: "Utah",
      zipCode: "84601",
      venue: "Pioneer Park",
      coordinates: [-111.6591, 40.2338]
    },
    startDate: new Date('2025-06-14'),
    endDate: new Date('2025-06-14'),
    startTime: "09:00",
    endTime: "14:00",
    organizer: {
      name: "Provo Farmers Market",
      email: "market@provo.org",
      phone: "(801) 852-6000",
      website: "https://www.provo.org/farmers-market"
    },
    maxTrucks: 6,
    registrationDeadline: new Date('2025-06-12'),
    entryFee: 50,
    expectedAttendance: 1500,
    amenities: ["electricity", "water", "parking", "restrooms"],
    requirements: ["Food handler's permit required", "Insurance certificate needed", "Utah County health permit"],
    tags: ["farmers-market", "weekly", "family-friendly", "local"],
    isPublic: true,
    isActive: true,
    weatherContingency: "Market continues unless severe weather",
    socialMedia: {
      website: "https://www.provo.org/farmers-market",
      facebook: "https://facebook.com/provofarmersmarket",
      instagram: "@provofarmersmarket"
    }
  },
  {
    name: "Ogden First Friday Art Stroll",
    description: "Monthly art walk in historic downtown Ogden featuring galleries, artists, and food trucks.",
    eventType: "festival",
    location: {
      address: "2549 Washington Blvd",
      city: "Ogden",
      state: "Utah",
      zipCode: "84401",
      venue: "Historic 25th Street",
      coordinates: [-111.9738, 41.2230]
    },
    startDate: new Date('2025-07-01'),
    endDate: new Date('2025-07-01'),
    startTime: "18:00",
    endTime: "22:00",
    organizer: {
      name: "Ogden Arts Council",
      email: "events@ogdenarts.org",
      phone: "(801) 392-4052",
      website: "https://www.ogdenarts.org"
    },
    maxTrucks: 10,
    registrationDeadline: new Date('2025-06-28'),
    entryFee: 40,
    expectedAttendance: 2500,
    amenities: ["electricity", "security", "parking", "restrooms"],
    requirements: ["Food handler's permit required", "Insurance certificate needed", "Weber County permit"],
    tags: ["art", "monthly", "historic", "downtown", "evening"],
    isPublic: true,
    isActive: true,
    weatherContingency: "Some covered areas available on 25th Street",
    socialMedia: {
      website: "https://www.ogdenarts.org",
      facebook: "https://facebook.com/ogdenartscouncil",
      instagram: "@ogdenarts"
    }
  },
  {
    name: "Corporate Event - Tech Company Lunch",
    description: "Private catering event for a major tech company's quarterly all-hands meeting. Looking for diverse food options.",
    eventType: "corporate",
    location: {
      address: "2795 E Cottonwood Pkwy",
      city: "Cottonwood Heights",
      state: "Utah",
      zipCode: "84121",
      venue: "Corporate Campus",
      coordinates: [-111.8113, 40.6169]
    },
    startDate: new Date('2025-08-15'),
    endDate: new Date('2025-08-15'),
    startTime: "11:30",
    endTime: "14:00",
    organizer: {
      name: "TechCorp Utah",
      email: "events@techcorp.com",
      phone: "(801) 555-0199",
      website: "https://www.techcorp.com"
    },
    maxTrucks: 5,
    registrationDeadline: new Date('2025-08-10'),
    entryFee: 0,
    expectedAttendance: 800,
    amenities: ["electricity", "water", "security", "parking", "wifi", "restrooms"],
    requirements: ["Food handler's permit required", "Insurance certificate needed", "Background checks for all staff"],
    tags: ["corporate", "private", "lunch", "tech", "employees"],
    isPublic: false,
    isActive: true,
    weatherContingency: "Indoor cafeteria space available as backup",
    socialMedia: {}
  }
];

async function seedEvents() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Create admin/organizer user if doesn't exist
    let organizer = await User.findOne({ email: 'events@utah-organizer.com' });
    if (!organizer) {
      const hashedPassword = await bcrypt.hash('organizer2024', 12);
      organizer = new User({
        name: 'Utah Event Organizer',
        email: 'events@utah-organizer.com',
        password: hashedPassword,
        role: 'admin'
      });
      await organizer.save();
      console.log('Created organizer account: events@utah-organizer.com');
    }

    // Clear existing events
    console.log('Clearing existing events...');
    await Event.deleteMany({});

    // Get some food trucks to assign to events
    const trucks = await FoodTruck.find().limit(10);
    console.log(`Found ${trucks.length} food trucks to assign to events`);

    // Create events
    console.log('Creating events...');
    for (let i = 0; i < UTAH_EVENTS.length; i++) {
      const eventData = UTAH_EVENTS[i];
      
      // Randomly assign some trucks to each event
      const numTrucksToAssign = Math.min(
        Math.floor(Math.random() * eventData.maxTrucks / 2) + 1,
        trucks.length
      );
      
      const shuffledTrucks = trucks.sort(() => 0.5 - Math.random());
      const assignedTrucks = shuffledTrucks.slice(0, numTrucksToAssign);
      
      const event = new Event({
        ...eventData,
        createdBy: organizer._id,
        updatedBy: organizer._id,
        participatingTrucks: assignedTrucks.map(truck => ({
          truck: truck._id,
          status: 'confirmed',
          confirmedAt: new Date()
        }))
      });
      
      await event.save();
      console.log(`Created event: ${eventData.name} (${assignedTrucks.length} trucks assigned)`);
    }

    console.log(`\n🎉 Successfully seeded ${UTAH_EVENTS.length} Utah events!`);
    console.log('\nEvent organizer login:');
    console.log('Email: events@utah-organizer.com');
    console.log('Password: organizer2024');
    console.log('\nEvents created:');
    UTAH_EVENTS.forEach((event, index) => {
      console.log(`${index + 1}. ${event.name} - ${event.location.city}, ${event.eventType}`);
    });

  } catch (error) {
    console.error('Error seeding events:', error);
  } finally {
    mongoose.connection.close();
    console.log('\nDatabase connection closed');
  }
}

// Run the seeding script
if (require.main === module) {
  seedEvents();
}

module.exports = { seedEvents, UTAH_EVENTS }; 
const mongoose = require('mongoose');
const User = require('./models/User');
const FoodTruck = require('./models/FoodTruck');

const MONGODB_URI = 'mongodb+srv://codycook:sLYlcz4fvFDVGKxk@cluster0.bpjvh.mongodb.net/foodtruckapp?retryWrites=true&w=majority';

// Utah-based food truck data with realistic locations
const utahFoodTrucksData = [
    {
        ownerEmail: 'owner@saltlakesliders.com',
        ownerName: 'Mike Thompson',
        businessName: 'Salt Lake Sliders',
        truck: {
            name: 'Salt Lake Sliders',
            description: 'Gourmet burgers and sliders made with locally sourced beef and fresh ingredients.',
            cuisine: 'American',
            phone: '(801) 555-0101',
            email: 'orders@saltlakesliders.com',
            location: {
                latitude: 40.7608,
                longitude: -111.8910,
                address: 'Liberty Park, Salt Lake City, UT'
            },
            menu: [
                { name: 'Classic Beef Slider', price: 8.99, description: 'Angus beef with lettuce, tomato, onion' },
                { name: 'BBQ Bacon Burger', price: 12.99, description: 'BBQ sauce, bacon, cheddar cheese' },
                { name: 'Veggie Slider', price: 7.99, description: 'House-made veggie patty with avocado' },
                { name: 'Sweet Potato Fries', price: 4.99, description: 'Crispy sweet potato fries with aioli' }
            ],
            operatingHours: 'Mon-Fri: 11AM-8PM, Sat-Sun: 10AM-9PM',
            isActive: true
        }
    },
    {
        ownerEmail: 'chef@mountainpizza.com',
        ownerName: 'Sarah Rodriguez',
        businessName: 'Mountain View Pizza Co',
        truck: {
            name: 'Mountain View Pizza Co',
            description: 'Wood-fired artisan pizzas with a view of the Wasatch Mountains.',
            cuisine: 'Italian',
            phone: '(801) 555-0102',
            email: 'hello@mountainpizza.com',
            location: {
                latitude: 40.7831,
                longitude: -111.8932,
                address: 'University of Utah Campus, Salt Lake City, UT'
            },
            menu: [
                { name: 'Margherita Pizza', price: 14.99, description: 'Fresh mozzarella, basil, tomato sauce' },
                { name: 'Pepperoni Supreme', price: 16.99, description: 'Double pepperoni, extra cheese' },
                { name: 'Mountain Veggie', price: 15.99, description: 'Bell peppers, mushrooms, olives, onions' },
                { name: 'Garlic Breadsticks', price: 6.99, description: 'Fresh baked with marinara sauce' }
            ],
            operatingHours: 'Tue-Sun: 12PM-9PM, Closed Mondays',
            isActive: true
        }
    },
    {
        ownerEmail: 'owner@deserttacos.com',
        ownerName: 'Carlos Martinez',
        businessName: 'Desert Bloom Tacos',
        truck: {
            name: 'Desert Bloom Tacos',
            description: 'Authentic Mexican street tacos with house-made salsas and fresh tortillas.',
            cuisine: 'Mexican',
            phone: '(801) 555-0103',
            email: 'info@deserttacos.com',
            location: {
                latitude: 40.2338,
                longitude: -111.6585,
                address: 'Provo Town Square, Provo, UT'
            },
            menu: [
                { name: 'Carne Asada Taco', price: 3.99, description: 'Grilled steak, onions, cilantro, lime' },
                { name: 'Al Pastor Taco', price: 3.99, description: 'Marinated pork, pineapple, onions' },
                { name: 'Fish Taco', price: 4.99, description: 'Beer-battered cod, cabbage slaw, chipotle crema' },
                { name: 'Elote Cup', price: 5.99, description: 'Mexican street corn with cotija cheese' }
            ],
            operatingHours: 'Daily: 11AM-10PM',
            isActive: true
        }
    },
    {
        ownerEmail: 'chef@beehivebbq.com',
        ownerName: 'Tom Wilson',
        businessName: 'Beehive BBQ',
        truck: {
            name: 'Beehive BBQ',
            description: 'Slow-smoked meats and traditional BBQ sides, Utah style.',
            cuisine: 'BBQ',
            phone: '(801) 555-0104',
            email: 'orders@beehivebbq.com',
            location: {
                latitude: 40.7589,
                longitude: -111.8883,
                address: 'Pioneer Park, Salt Lake City, UT'
            },
            menu: [
                { name: 'Pulled Pork Sandwich', price: 11.99, description: '12-hour smoked pork with coleslaw' },
                { name: 'Brisket Platter', price: 16.99, description: 'Sliced brisket with two sides' },
                { name: 'BBQ Ribs (Half Rack)', price: 18.99, description: 'Dry-rubbed ribs with house sauce' },
                { name: 'Mac & Cheese', price: 5.99, description: 'Creamy three-cheese blend' }
            ],
            operatingHours: 'Wed-Sun: 12PM-8PM, Closed Mon-Tue',
            isActive: true
        }
    },
    {
        ownerEmail: 'owner@wafflecrave.com',
        ownerName: 'Emma Johnson',
        businessName: 'Waffle Cravings',
        truck: {
            name: 'Waffle Cravings',
            description: 'Sweet and savory gourmet waffles for breakfast, lunch, and dessert.',
            cuisine: 'Breakfast',
            phone: '(801) 555-0105',
            email: 'hello@wafflecrave.com',
            location: {
                latitude: 40.7505,
                longitude: -111.8638,
                address: 'City Creek Center, Salt Lake City, UT'
            },
            menu: [
                { name: 'Classic Belgian Waffle', price: 8.99, description: 'With butter, syrup, and powdered sugar' },
                { name: 'Chicken & Waffle', price: 13.99, description: 'Fried chicken breast with maple syrup' },
                { name: 'Berry Bliss Waffle', price: 10.99, description: 'Fresh berries and whipped cream' },
                { name: 'Bacon Waffle Sandwich', price: 9.99, description: 'Scrambled eggs, bacon, cheese' }
            ],
            operatingHours: 'Daily: 7AM-3PM',
            isActive: true
        }
    },
    {
        ownerEmail: 'chef@asiafusion.com',
        ownerName: 'Kevin Park',
        businessName: 'Seoul Kitchen',
        truck: {
            name: 'Seoul Kitchen',
            description: 'Korean-American fusion cuisine with bold flavors and fresh ingredients.',
            cuisine: 'Korean',
            phone: '(801) 555-0106',
            email: 'orders@asiafusion.com',
            location: {
                latitude: 40.7282,
                longitude: -111.9013,
                address: 'West Jordan City Park, West Jordan, UT'
            },
            menu: [
                { name: 'Korean BBQ Bowl', price: 12.99, description: 'Bulgogi beef over rice with vegetables' },
                { name: 'Kimchi Fried Rice', price: 10.99, description: 'Spicy kimchi fried rice with egg' },
                { name: 'Korean Tacos (3)', price: 11.99, description: 'Bulgogi beef in soft tortillas' },
                { name: 'Mandu Dumplings', price: 7.99, description: 'Pan-fried pork and vegetable dumplings' }
            ],
            operatingHours: 'Mon-Sat: 11AM-9PM, Closed Sundays',
            isActive: true
        }
    },
    {
        ownerEmail: 'owner@mountaincoffee.com',
        ownerName: 'Lisa Anderson',
        businessName: 'Mountain Peak Coffee',
        truck: {
            name: 'Mountain Peak Coffee',
            description: 'Locally roasted coffee, pastries, and light breakfast options.',
            cuisine: 'Coffee',
            phone: '(801) 555-0107',
            email: 'info@mountaincoffee.com',
            location: {
                latitude: 40.2677,
                longitude: -111.6947,
                address: 'BYU Campus, Provo, UT'
            },
            menu: [
                { name: 'Mountain Peak Latte', price: 4.99, description: 'House blend espresso with steamed milk' },
                { name: 'Breakfast Burrito', price: 7.99, description: 'Eggs, cheese, potatoes, choice of meat' },
                { name: 'Fresh Croissant', price: 3.99, description: 'Buttery croissant with jam' },
                { name: 'Iced Cold Brew', price: 3.99, description: 'Smooth cold brew with optional milk' }
            ],
            operatingHours: 'Mon-Fri: 6AM-2PM, Sat: 7AM-1PM',
            isActive: true
        }
    },
    {
        ownerEmail: 'chef@seafoodshack.com',
        ownerName: 'David Chen',
        businessName: 'Ocean Breeze Seafood',
        truck: {
            name: 'Ocean Breeze Seafood',
            description: 'Fresh seafood brought to the mountains - fish tacos, shrimp, and more.',
            cuisine: 'Seafood',
            phone: '(801) 555-0108',
            email: 'orders@seafoodshack.com',
            location: {
                latitude: 40.7067,
                longitude: -111.9382,
                address: 'Millcreek Common, Millcreek, UT'
            },
            menu: [
                { name: 'Fish & Chips', price: 13.99, description: 'Beer-battered cod with seasoned fries' },
                { name: 'Shrimp Po\' Boy', price: 12.99, description: 'Fried shrimp with lettuce and remoulade' },
                { name: 'Salmon Bowl', price: 15.99, description: 'Grilled salmon over rice with vegetables' },
                { name: 'Clam Chowder', price: 6.99, description: 'Creamy New England style chowder' }
            ],
            operatingHours: 'Tue-Sat: 11AM-8PM, Sun: 12PM-6PM',
            isActive: true
        }
    },
    {
        ownerEmail: 'owner@sweettreats.com',
        ownerName: 'Rachel Green',
        businessName: 'Sweet Dreams Desserts',
        truck: {
            name: 'Sweet Dreams Desserts',
            description: 'Artisan ice cream, cookies, and desserts made fresh daily.',
            cuisine: 'Desserts',
            phone: '(801) 555-0109',
            email: 'hello@sweettreats.com',
            location: {
                latitude: 40.6892,
                longitude: -111.8447,
                address: 'Murray Park, Murray, UT'
            },
            menu: [
                { name: 'Artisan Ice Cream Scoop', price: 4.99, description: 'Choice of 12 rotating flavors' },
                { name: 'Warm Cookie Sandwich', price: 6.99, description: 'Ice cream between two warm cookies' },
                { name: 'Funnel Cake', price: 8.99, description: 'Fresh funnel cake with powdered sugar' },
                { name: 'Milkshake', price: 5.99, description: 'Thick milkshake with whipped cream' }
            ],
            operatingHours: 'Daily: 12PM-10PM',
            isActive: true
        }
    },
    {
        ownerEmail: 'chef@healthybowls.com',
        ownerName: 'Amanda White',
        businessName: 'Fresh & Fit Bowls',
        truck: {
            name: 'Fresh & Fit Bowls',
            description: 'Healthy grain bowls, salads, and smoothies with organic ingredients.',
            cuisine: 'Healthy',
            phone: '(801) 555-0110',
            email: 'info@healthybowls.com',
            location: {
                latitude: 40.7755,
                longitude: -111.9044,
                address: 'Sugarhouse Park, Salt Lake City, UT'
            },
            menu: [
                { name: 'Power Bowl', price: 11.99, description: 'Quinoa, grilled chicken, avocado, vegetables' },
                { name: 'Mediterranean Bowl', price: 10.99, description: 'Falafel, hummus, cucumber, olives' },
                { name: 'Green Goddess Salad', price: 9.99, description: 'Mixed greens with house goddess dressing' },
                { name: 'Protein Smoothie', price: 6.99, description: 'Banana, berries, protein powder, almond milk' }
            ],
            operatingHours: 'Mon-Sat: 8AM-6PM, Sun: 9AM-4PM',
            isActive: true
        }
    }
];

async function populateUtahFoodTrucks() {
    try {
        console.log('🏔️ Starting Utah Food Truck Population...\n');
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connected to MongoDB Atlas\n');

        console.log('🧹 Verifying clean database...');
        const existingUsers = await User.countDocuments();
        const existingTrucks = await FoodTruck.countDocuments();
        console.log(`📊 Current users: ${existingUsers}`);
        console.log(`📊 Current trucks: ${existingTrucks}\n`);

        console.log('👥 Creating food truck owners...');
        const createdOwners = [];

        for (let i = 0; i < utahFoodTrucksData.length; i++) {
            const data = utahFoodTrucksData[i];
            
            // Create owner with proper MongoDB ObjectId
            const owner = new User({
                name: data.ownerName,
                email: data.ownerEmail,
                password: 'password123', // Simple password for demo
                role: 'owner',
                businessName: data.businessName,
                isActive: true,
                createdAt: new Date()
            });

            await owner.save();
            
            // Set userId to match _id for consistency
            owner.userId = owner._id.toString();
            await owner.save();
            
            createdOwners.push(owner);
            console.log(`✅ Created owner: ${data.ownerName} (${owner._id})`);
        }

        console.log(`\n🚚 Creating ${utahFoodTrucksData.length} food trucks...\n`);

        for (let i = 0; i < utahFoodTrucksData.length; i++) {
            const data = utahFoodTrucksData[i];
            const owner = createdOwners[i];
            
            // Create food truck with proper owner reference
            const truck = new FoodTruck({
                id: `truck_${Date.now()}_${i}`, // Unique truck ID
                ownerId: owner._id.toString(), // Use MongoDB ObjectId
                name: data.truck.name,
                description: data.truck.description,
                cuisine: data.truck.cuisine,
                phone: data.truck.phone,
                email: data.truck.email,
                location: data.truck.location,
                menu: data.truck.menu,
                operatingHours: data.truck.operatingHours,
                isActive: data.truck.isActive,
                imageUrl: `https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=${encodeURIComponent(data.truck.name)}`,
                rating: (Math.random() * 2 + 3).toFixed(1), // Random rating between 3.0-5.0
                totalReviews: Math.floor(Math.random() * 200) + 10,
                createdAt: new Date(),
                lastUpdated: new Date()
            });

            await truck.save();
            
            console.log(`🚚 Created: ${data.truck.name}`);
            console.log(`   📍 Location: ${data.truck.location.address}`);
            console.log(`   🍽️ Cuisine: ${data.truck.cuisine}`);
            console.log(`   👤 Owner: ${owner.name} (${owner._id})`);
            console.log(`   ⭐ Rating: ${truck.rating} (${truck.totalReviews} reviews)\n`);
        }

        // Final verification
        console.log('🔍 FINAL VERIFICATION:');
        console.log('=' .repeat(50));
        const finalUsers = await User.countDocuments();
        const finalTrucks = await FoodTruck.countDocuments();
        
        console.log(`👥 Total users created: ${finalUsers}`);
        console.log(`🚚 Total food trucks created: ${finalTrucks}`);
        
        // Show sample data
        console.log('\n📋 SAMPLE FOOD TRUCKS:');
        const sampleTrucks = await FoodTruck.find().limit(3);
        sampleTrucks.forEach(truck => {
            console.log(`🚚 ${truck.name} - ${truck.cuisine} - ${truck.location.address}`);
        });

        console.log('\n🎉 Utah food truck population completed successfully!');
        console.log('💡 All trucks have consistent MongoDB ObjectIds');
        console.log('🏔️ Ready for testing in Utah! 🏔️');

    } catch (error) {
        console.error('❌ Error during population:', error);
    } finally {
        console.log('\n🔌 Disconnecting from MongoDB...');
        await mongoose.disconnect();
        console.log('✅ Disconnected successfully');
        process.exit(0);
    }
}

populateUtahFoodTrucks(); 
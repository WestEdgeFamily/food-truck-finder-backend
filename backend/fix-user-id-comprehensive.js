const mongoose = require('mongoose');
const User = require('./models/User');
const FoodTruck = require('./models/FoodTruck');
const Favorite = require('./models/Favorite');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://codycook:sLYlcz4fvFDVGKxk@cluster0.bpjvh.mongodb.net/foodtruckapp?retryWrites=true&w=majority';

async function diagnosisAndFix() {
    try {
        console.log('🔍 Starting comprehensive user ID diagnosis and fix...\n');
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connected to MongoDB Atlas\n');

        // 1. Analyze all users in database
        console.log('👥 ANALYZING USERS:');
        console.log('=' .repeat(50));
        const allUsers = await User.find({});
        console.log(`📊 Total users in database: ${allUsers.length}`);
        
        allUsers.forEach((user, index) => {
            console.log(`${index + 1}. User:`);
            console.log(`   MongoDB _id: ${user._id}`);
            console.log(`   userId field: ${user.userId || 'MISSING'}`);
            console.log(`   Email: ${user.email}`);
            console.log(`   Role: ${user.role}`);
            console.log(`   Business Name: ${user.businessName || 'N/A'}`);
            console.log('');
        });

        // 2. Analyze all food trucks
        console.log('\n🚚 ANALYZING FOOD TRUCKS:');
        console.log('=' .repeat(50));
        const allTrucks = await FoodTruck.find({});
        console.log(`📊 Total food trucks in database: ${allTrucks.length}`);
        
        allTrucks.forEach((truck, index) => {
            console.log(`${index + 1}. Food Truck:`);
            console.log(`   MongoDB _id: ${truck._id}`);
            console.log(`   Custom id field: ${truck.id || 'MISSING'}`);
            console.log(`   Name: ${truck.name}`);
            console.log(`   Owner ID: ${truck.ownerId || 'MISSING'}`);
            console.log(`   Menu items: ${truck.menu?.length || 0}`);
            console.log('');
        });

        // 3. Find orphaned food trucks (trucks with owners that don't exist)
        console.log('\n🔍 FINDING ORPHANED FOOD TRUCKS:');
        console.log('=' .repeat(50));
        for (const truck of allTrucks) {
            if (truck.ownerId) {
                // Try to find owner by various methods
                let owner = await User.findOne({ _id: truck.ownerId });
                if (!owner) {
                    owner = await User.findOne({ userId: truck.ownerId });
                }
                
                if (!owner) {
                    console.log(`❌ ORPHANED TRUCK: ${truck.name} (ID: ${truck.id})`);
                    console.log(`   Owner ID "${truck.ownerId}" not found in users table`);
                    console.log(`   Available users: ${allUsers.map(u => u._id).join(', ')}`);
                    
                    // Try to find a matching user by business name
                    const matchingUser = allUsers.find(u => 
                        u.businessName && truck.businessName && 
                        u.businessName.toLowerCase().includes(truck.businessName.toLowerCase().split(' ')[0])
                    );
                    
                    if (matchingUser) {
                        console.log(`   🔧 FIXING: Updating owner to ${matchingUser.email} (${matchingUser._id})`);
                        await FoodTruck.findByIdAndUpdate(truck._id, { ownerId: matchingUser._id });
                        console.log(`   ✅ Fixed truck ownership`);
                    } else {
                        console.log(`   ⚠️ No matching user found by business name`);
                    }
                } else {
                    console.log(`✅ Truck "${truck.name}" has valid owner: ${owner.email}`);
                }
            }
        }

        // 4. Standardize user IDs
        console.log('\n🔧 STANDARDIZING USER IDS:');
        console.log('=' .repeat(50));
        for (const user of allUsers) {
            if (!user.userId) {
                // Set userId to match _id for consistency
                console.log(`🔧 Adding missing userId to ${user.email}`);
                await User.findByIdAndUpdate(user._id, { userId: user._id.toString() });
                console.log(`   ✅ Set userId to: ${user._id}`);
            } else if (user.userId !== user._id.toString()) {
                console.log(`⚠️ User ${user.email} has mismatched IDs:`);
                console.log(`   MongoDB _id: ${user._id}`);
                console.log(`   userId field: ${user.userId}`);
                console.log(`   🔧 Updating userId to match _id`);
                await User.findByIdAndUpdate(user._id, { userId: user._id.toString() });
                console.log(`   ✅ Standardized userId`);
            }
        }

        // 5. Create test user if needed
        console.log('\n👤 ENSURING TEST USER EXISTS:');
        console.log('=' .repeat(50));
        let testOwner = await User.findOne({ email: 'vincent.cody298@gmail.com' });
        if (!testOwner) {
            console.log(`🔧 Creating test owner user...`);
            testOwner = new User({
                _id: 'owner_test_' + Date.now(),
                userId: 'owner_test_' + Date.now(),
                name: 'Cody Test Owner',
                email: 'vincent.cody298@gmail.com',
                password: 'password123',
                role: 'owner',
                businessName: 'Cody\'s Test Truck',
                createdAt: new Date()
            });
            await testOwner.save();
            console.log(`   ✅ Created test owner: ${testOwner.email}`);
        } else {
            console.log(`✅ Test owner exists: ${testOwner.email}`);
            // Ensure userId field is set
            if (!testOwner.userId) {
                await User.findByIdAndUpdate(testOwner._id, { userId: testOwner._id.toString() });
                console.log(`   🔧 Added missing userId field`);
            }
        }

        // 6. Create/fix test food truck
        console.log('\n🚚 ENSURING TEST FOOD TRUCK EXISTS:');
        console.log('=' .repeat(50));
        let testTruck = await FoodTruck.findOne({ ownerId: testOwner._id });
        if (!testTruck) {
            // Also check by userId field
            testTruck = await FoodTruck.findOne({ ownerId: testOwner.userId });
        }
        
        if (!testTruck) {
            console.log(`🔧 Creating test food truck...`);
            testTruck = new FoodTruck({
                id: 'truck_test_' + Date.now(),
                name: 'Cody\'s Test Truck',
                businessName: 'Cody\'s Test Truck',
                description: 'This is an updated description to test persistence',
                cuisine: 'American',
                rating: 4.5,
                image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
                email: 'vincent.cody298@gmail.com',
                website: '',
                location: {
                    latitude: 40.611664,
                    longitude: -111.849221,
                    address: 'Test Location, Salt Lake City, UT'
                },
                hours: 'Mon-Sat: 11:00 AM - 9:00 PM, Sun: Closed',
                menu: [
                    { name: 'burger', description: 'burger', price: 10.00, category: 'American' },
                    { name: 'steak', description: 'steak', price: 50.00, category: 'American' }
                ],
                ownerId: testOwner._id,
                isOpen: false,
                isActive: true,
                createdAt: new Date(),
                lastUpdated: new Date(),
                reviewCount: 0,
                schedule: {
                    monday: { open: '11:00', close: '21:00', isOpen: true },
                    tuesday: { open: '11:00', close: '21:00', isOpen: true },
                    wednesday: { open: '11:00', close: '21:00', isOpen: true },
                    thursday: { open: '11:00', close: '21:00', isOpen: true },
                    friday: { open: '11:00', close: '21:00', isOpen: true },
                    saturday: { open: '11:00', close: '21:00', isOpen: true },
                    sunday: { open: '11:00', close: '21:00', isOpen: true }
                },
                posSettings: {
                    parentAccountId: testOwner._id,
                    childAccounts: [],
                    allowPosTracking: true,
                    posApiKey: `pos_${testOwner._id}_${Date.now()}`,
                    posWebhookUrl: null
                }
            });
            await testTruck.save();
            console.log(`   ✅ Created test truck: ${testTruck.name} (ID: ${testTruck.id})`);
        } else {
            console.log(`✅ Test truck exists: ${testTruck.name} (ID: ${testTruck.id})`);
            // Update owner ID to ensure consistency
            if (testTruck.ownerId !== testOwner._id.toString()) {
                await FoodTruck.findByIdAndUpdate(testTruck._id, { ownerId: testOwner._id });
                console.log(`   🔧 Fixed owner ID reference`);
            }
        }

        // 7. Final verification
        console.log('\n✅ FINAL VERIFICATION:');
        console.log('=' .repeat(50));
        
        const finalUsers = await User.find({});
        const finalTrucks = await FoodTruck.find({});
        
        console.log(`📊 Users: ${finalUsers.length}`);
        console.log(`📊 Food Trucks: ${finalTrucks.length}`);
        
        console.log('\n📋 USER-TRUCK RELATIONSHIPS:');
        for (const truck of finalTrucks) {
            const owner = await User.findOne({ 
                $or: [
                    { _id: truck.ownerId },
                    { userId: truck.ownerId }
                ]
            });
            
            if (owner) {
                console.log(`✅ ${truck.name} → ${owner.email} (${owner.role})`);
            } else {
                console.log(`❌ ${truck.name} → OWNER NOT FOUND (${truck.ownerId})`);
            }
        }

        console.log('\n🎉 Diagnosis and fix completed successfully!');
        console.log('\n📱 For mobile app testing, use:');
        console.log(`   Email: ${testOwner.email}`);
        console.log(`   Password: password123`);
        console.log(`   Role: owner`);
        console.log(`   Truck ID: ${testTruck.id}`);

    } catch (error) {
        console.error('❌ Error during diagnosis and fix:', error);
    } finally {
        await mongoose.disconnect();
        console.log('\n🔌 Disconnected from MongoDB');
    }
}

// Run if called directly
if (require.main === module) {
    diagnosisAndFix();
}

module.exports = { diagnosisAndFix }; 
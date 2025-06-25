const mongoose = require('mongoose');
const User = require('./models/User');
const FoodTruck = require('./models/FoodTruck');
const Favorite = require('./models/Favorite');

const MONGODB_URI = 'mongodb+srv://codycook:sLYlcz4fvFDVGKxk@cluster0.bpjvh.mongodb.net/foodtruckapp?retryWrites=true&w=majority';

async function clearProblematicUsers() {
    try {
        console.log('🧹 Starting user cleanup process...\n');
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connected to MongoDB Atlas\n');

        // 1. Find all users and analyze them
        console.log('📊 ANALYZING EXISTING USERS:');
        console.log('=' .repeat(50));
        const allUsers = await User.find({});
        console.log(`📈 Total users found: ${allUsers.length}\n`);

        let problematicUsers = [];
        let goodUsers = [];

        allUsers.forEach(user => {
            const hasConsistentId = user.userId && user.userId === user._id.toString();
            const isTestUser = user.email.includes('test') || user.email.includes('example');
            
            console.log(`👤 User: ${user.email}`);
            console.log(`   🆔 MongoDB _id: ${user._id}`);
            console.log(`   🔑 userId field: ${user.userId || 'MISSING'}`);
            console.log(`   ✅ Consistent: ${hasConsistentId ? 'YES' : 'NO'}`);
            console.log(`   🧪 Test user: ${isTestUser ? 'YES' : 'NO'}`);
            
            if (!hasConsistentId || isTestUser) {
                problematicUsers.push(user);
                console.log(`   ❌ MARKED FOR REMOVAL\n`);
            } else {
                goodUsers.push(user);
                console.log(`   ✅ KEEPING\n`);
            }
        });

        console.log('📋 CLEANUP SUMMARY:');
        console.log('=' .repeat(50));
        console.log(`✅ Users to keep: ${goodUsers.length}`);
        console.log(`❌ Users to remove: ${problematicUsers.length}\n`);

        if (problematicUsers.length === 0) {
            console.log('🎉 No problematic users found! Database is clean.');
            return;
        }

        // 2. Remove problematic users and their related data
        console.log('🗑️ REMOVING PROBLEMATIC USERS:');
        console.log('=' .repeat(50));

        for (const user of problematicUsers) {
            console.log(`🗑️ Removing user: ${user.email} (${user._id})`);
            
            // Remove user's food trucks
            const userTrucks = await FoodTruck.find({ ownerId: { $in: [user._id.toString(), user.userId] } });
            if (userTrucks.length > 0) {
                console.log(`   📱 Found ${userTrucks.length} food truck(s) to remove`);
                await FoodTruck.deleteMany({ ownerId: { $in: [user._id.toString(), user.userId] } });
            }
            
            // Remove user's favorites
            const userFavorites = await Favorite.find({ userId: { $in: [user._id.toString(), user.userId] } });
            if (userFavorites.length > 0) {
                console.log(`   ⭐ Found ${userFavorites.length} favorite(s) to remove`);
                await Favorite.deleteMany({ userId: { $in: [user._id.toString(), user.userId] } });
            }
            
            // Remove the user
            await User.findByIdAndDelete(user._id);
            console.log(`   ✅ User removed successfully\n`);
        }

        // 3. Final verification
        console.log('🔍 FINAL VERIFICATION:');
        console.log('=' .repeat(50));
        const remainingUsers = await User.find({});
        console.log(`📊 Remaining users: ${remainingUsers.length}`);
        
        remainingUsers.forEach(user => {
            console.log(`✅ ${user.email} - ID: ${user._id} - Consistent: ${user.userId === user._id.toString()}`);
        });

        console.log('\n🎉 User cleanup completed successfully!');
        console.log('💡 New user registrations will now have consistent IDs.');

    } catch (error) {
        console.error('❌ Error during cleanup:', error);
    } finally {
        console.log('\n🔌 Disconnecting from MongoDB...');
        await mongoose.disconnect();
        console.log('✅ Disconnected successfully');
        process.exit(0);
    }
}

clearProblematicUsers(); 
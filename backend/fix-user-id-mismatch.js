const mongoose = require('mongoose');
const User = require('./models/User');

const MONGODB_URI = 'mongodb+srv://admin:admin123@cluster0.kzrfb.mongodb.net/foodtruckapp?retryWrites=true&w=majority';

async function testUserIdFormats() {
    try {
        console.log('🔍 Connecting to MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        // Find all users to see ID formats
        console.log('\n📋 All users in database:');
        const allUsers = await User.find({}, 'userId email role').limit(10);
        allUsers.forEach(user => {
            console.log(`   ID: ${user.userId} | Email: ${user.email} | Role: ${user.role}`);
        });

        // Test common ID patterns
        const testIds = [
            'user1', 'user2', 'user3',
            'owner1', 'owner2',
            // Will also test any timestamp-based IDs we find
        ];

        // Add any timestamp-based IDs from the database
        const timestampUsers = allUsers.filter(user => 
            user.userId && user.userId.includes('_') && user.userId.length > 10
        );
        timestampUsers.forEach(user => testIds.push(user.userId));

        console.log('\n🧪 Testing password change for different user IDs:');
        
        for (const userId of testIds) {
            try {
                const user = await User.findOne({ userId: userId });
                if (user) {
                    console.log(`✅ Found user: ${userId} (${user.email})`);
                    
                    // Test password change simulation
                    const updateResult = await User.findOneAndUpdate(
                        { userId: userId },
                        { password: 'test_new_password_hash' },
                        { new: true }
                    );
                    
                    if (updateResult) {
                        console.log(`   ✅ Password change would work for ${userId}`);
                        // Revert the test change
                        await User.findOneAndUpdate(
                            { userId: userId },
                            { password: user.password },
                            { new: true }
                        );
                    }
                } else {
                    console.log(`❌ User not found: ${userId}`);
                }
            } catch (error) {
                console.log(`❌ Error testing ${userId}:`, error.message);
            }
        }

        // Test flexible user search
        console.log('\n🔍 Testing flexible user search patterns:');
        
        // Search for users with email patterns
        const emailPatterns = ['@gmail.com', '@yahoo.com', '@test.com'];
        for (const pattern of emailPatterns) {
            const users = await User.find({ email: { $regex: pattern, $options: 'i' } }, 'userId email');
            if (users.length > 0) {
                console.log(`📧 Users with ${pattern}:`);
                users.forEach(user => {
                    console.log(`   ${user.userId} - ${user.email}`);
                });
            }
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await mongoose.disconnect();
        console.log('\n🔌 Disconnected from MongoDB');
    }
}

// Enhanced user finder function
async function findUserFlexibly(identifier) {
    // Try exact match first
    let user = await User.findOne({ userId: identifier });
    if (user) return user;
    
    // Try email match
    user = await User.findOne({ email: identifier });
    if (user) return user;
    
    // Try partial userId match (for timestamp-based IDs)
    user = await User.findOne({ userId: { $regex: identifier, $options: 'i' } });
    if (user) return user;
    
    // Try MongoDB _id if it looks like one
    if (identifier.match(/^[0-9a-fA-F]{24}$/)) {
        user = await User.findById(identifier);
        if (user) return user;
    }
    
    return null;
}

// Test the flexible finder
async function testFlexibleFinder() {
    try {
        await mongoose.connect(MONGODB_URI);
        
        console.log('\n🔍 Testing flexible user finder:');
        const testIdentifiers = [
            'user1',
            'user_12345',
            'test@gmail.com',
            'owner1'
        ];
        
        for (const id of testIdentifiers) {
            const user = await findUserFlexibly(id);
            if (user) {
                console.log(`✅ Found: ${id} -> ${user.userId} (${user.email})`);
            } else {
                console.log(`❌ Not found: ${id}`);
            }
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await mongoose.disconnect();
    }
}

// Run the tests
if (require.main === module) {
    console.log('🚀 Starting User ID Mismatch Analysis...\n');
    testUserIdFormats().then(() => {
        console.log('\n' + '='.repeat(50));
        return testFlexibleFinder();
    });
}

module.exports = { findUserFlexibly }; 
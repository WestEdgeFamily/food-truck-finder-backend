const axios = require('axios');

// Test the real-time GPS tracking features
async function testRealtimeFeatures() {
    console.log('🚀 Testing Real-time GPS Tracking Features\n');

    try {
        // 1. Login as truck owner
        console.log('1. Logging in as truck owner...');
        const loginResponse = await axios.post('http://localhost:3001/api/auth/login', {
            email: 'test@example.com',
            password: 'password123'
        });
        
        const token = loginResponse.data.token;
        console.log('✅ Login successful');

        // 2. Get truck info
        console.log('\n2. Getting truck information...');
        const truckResponse = await axios.get('http://localhost:3001/api/foodtrucks/my-truck', {
            headers: { Authorization: `Bearer ${token}` }
        });
        
        const truckId = truckResponse.data._id;
        const truckName = truckResponse.data.name;
        console.log(`✅ Found truck: ${truckName} (ID: ${truckId})`);

        // 3. Start GPS tracking session
        console.log('\n3. Starting GPS tracking session...');
        await axios.post(`http://localhost:3001/api/foodtrucks/${truckId}/start-tracking`, {}, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('✅ GPS tracking session started');

        // 4. Simulate live GPS updates
        console.log('\n4. Simulating live GPS updates...');
        const locations = [
            { lat: 40.7589, lng: -73.9851, name: "Times Square, NYC" },
            { lat: 40.7614, lng: -73.9776, name: "Bryant Park, NYC" },
            { lat: 40.7505, lng: -73.9934, name: "Madison Square Garden, NYC" },
            { lat: 40.7282, lng: -74.0776, name: "World Trade Center, NYC" }
        ];

        for (let i = 0; i < locations.length; i++) {
            const location = locations[i];
            
            console.log(`📍 Updating location to: ${location.name}`);
            
            await axios.put(`http://localhost:3001/api/foodtrucks/${truckId}/live-location`, {
                latitude: location.lat,
                longitude: location.lng,
                accuracy: Math.random() * 10 + 5, // 5-15m accuracy
                heading: Math.random() * 360,
                speed: Math.random() * 20, // 0-20 m/s
                notes: `Live GPS update from ${location.name}`
            }, {
                headers: { 
                    Authorization: `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });
            
            console.log(`✅ Location updated successfully`);
            
            // Wait 3 seconds between updates
            if (i < locations.length - 1) {
                console.log('⏳ Waiting 3 seconds...\n');
                await new Promise(resolve => setTimeout(resolve, 3000));
            }
        }

        // 5. Stop GPS tracking
        console.log('\n5. Stopping GPS tracking session...');
        await axios.post(`http://localhost:3001/api/foodtrucks/${truckId}/stop-tracking`, {}, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('✅ GPS tracking session stopped');

        console.log('\n🎉 Real-time GPS tracking test completed successfully!');
        console.log('\n📱 What customers will see:');
        console.log('   • Live location updates in real-time');
        console.log('   • "LIVE" badges on actively tracked trucks');
        console.log('   • Push notifications for favorite trucks');
        console.log('   • Real-time connection status indicator');
        console.log('   • Live updates feed with timestamps');
        
        console.log('\n🚚 What truck owners get:');
        console.log('   • Beautiful GPS tracking dashboard');
        console.log('   • Real-time accuracy and speed display');
        console.log('   • Auto-update every 30 seconds option');
        console.log('   • Live update log with timestamps');
        console.log('   • One-click start/stop tracking');

    } catch (error) {
        console.error('❌ Error during testing:', error.response?.data || error.message);
    }
}

// Run the test
testRealtimeFeatures(); 
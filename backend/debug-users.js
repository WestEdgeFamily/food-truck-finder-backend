const https = require('https');

// Test the actual deployed backend to see what users exist
async function debugUsers() {
  console.log('🔍 Debugging user database...');
  
  // Try to login with a known user to see what the response looks like
  const testLogin = {
    email: 'john@customer.com',
    password: 'password123',
    role: 'customer'
  };
  
  const postData = JSON.stringify(testLogin);
  
  const options = {
    hostname: 'food-truck-finder-api.onrender.com',
    port: 443,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  return new Promise((resolve) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`📥 Login test status: ${res.statusCode}`);
        console.log(`📥 Login test response: ${data}`);
        
        if (res.statusCode === 200) {
          try {
            const response = JSON.parse(data);
            console.log('✅ Login successful! User data:');
            console.log(`   User ID: ${response.user._id}`);
            console.log(`   User Email: ${response.user.email}`);
            console.log(`   User Role: ${response.user.role}`);
            
            // Now test password change with this real user
            testPasswordChange(response.user._id, 'password123', 'newPassword123');
          } catch (e) {
            console.log('❌ Failed to parse login response');
          }
        } else {
          console.log('❌ Login failed - no users to test with');
        }
        
        resolve();
      });
    });
    
    req.on('error', (e) => {
      console.error(`❌ Login test error: ${e.message}`);
      resolve();
    });
    
    req.write(postData);
    req.end();
  });
}

async function testPasswordChange(userId, currentPassword, newPassword) {
  console.log(`\n🔐 Testing password change with real user ID: ${userId}`);
  
  const testData = {
    userId: userId,
    currentPassword: currentPassword,
    newPassword: newPassword
  };
  
  const postData = JSON.stringify(testData);
  
  const options = {
    hostname: 'food-truck-finder-api.onrender.com',
    port: 443,
    path: '/api/users/change-password',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  return new Promise((resolve) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`📥 Password change status: ${res.statusCode}`);
        console.log(`📥 Password change response: ${data}`);
        
        try {
          const response = JSON.parse(data);
          if (response.debug) {
            console.log('🔍 Debug info from backend:');
            console.log(`   User ID sent: ${response.debug.userId}`);
            console.log(`   Old password: ${response.debug.oldPassword}`);
            console.log(`   New password: ${response.debug.newPassword}`);
            console.log(`   Updated password: ${response.debug.updatedPassword}`);
          }
        } catch (e) {
          console.log('❌ Failed to parse password change response');
        }
        
        resolve();
      });
    });
    
    req.on('error', (e) => {
      console.error(`❌ Password change test error: ${e.message}`);
      resolve();
    });
    
    req.write(postData);
    req.end();
  });
}

debugUsers(); 
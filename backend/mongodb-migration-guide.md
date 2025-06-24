# MongoDB Atlas Migration Guide

## 🎯 Step 1: Create MongoDB Atlas Account

1. **Go to:** https://www.mongodb.com/atlas
2. **Click:** "Try Free"
3. **Sign up** with email or Google
4. **Choose:** "Free" tier (M0) - $0 forever
5. **Select cloud provider:** AWS (default is fine)
6. **Choose region:** Closest to you (US East recommended)
7. **Cluster name:** Leave default or name it "food-truck-db"
8. **Click:** "Create Deployment"

## 🔑 Step 2: Set Up Database Access

1. **Create Database User:**
   - Username: `foodtruckuser`
   - Password: Generate a secure password (save this!)
   - Click "Create User"

2. **Set Network Access:**
   - Click "Add IP Address"
   - Choose "Allow access from anywhere" (0.0.0.0/0)
   - Click "Confirm"

## 📝 Step 3: Get Connection String

1. **Click:** "Connect" button on your cluster
2. **Choose:** "Drivers"
3. **Select:** Node.js version 4.1 or later
4. **Copy the connection string** - it looks like:
   ```
   mongodb+srv://foodtruckuser:<password>@cluster0.abc123.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0
   ```
5. **Replace** `<password>` with your actual password

## 🔧 Step 4: Update Your Code

### A. Add to package.json
Add mongoose dependency:
```json
{
  "dependencies": {
    "mongoose": "^8.0.0"
  }
}
```

### B. Set Environment Variable in Render
1. Go to your Render dashboard
2. Click on your service
3. Go to "Environment" tab
4. Add new environment variable:
   - **Key:** `MONGODB_URI`
   - **Value:** Your connection string from Step 3

### C. Create Models Directory
Create these files in `/backend/models/`:

**User.js:**
```javascript
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['customer', 'owner'], required: true },
  businessName: { type: String },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);
```

**FoodTruck.js:**
```javascript
const mongoose = require('mongoose');

const foodTruckSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  businessName: { type: String },
  description: { type: String },
  cuisine: { type: String },
  rating: { type: Number, default: 0 },
  image: { type: String },
  location: {
    latitude: { type: Number },
    longitude: { type: Number },
    address: { type: String }
  },
  hours: { type: String },
  menu: [{
    name: { type: String },
    price: { type: Number },
    description: { type: String }
  }],
  ownerId: { type: String, required: true },
  isOpen: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  lastUpdated: { type: Date, default: Date.now },
  reviewCount: { type: Number, default: 0 }
});

module.exports = mongoose.model('FoodTruck', foodTruckSchema);
```

**Favorite.js:**
```javascript
const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  truckId: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

favoriteSchema.index({ userId: 1, truckId: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema);
```

## 🚀 Step 5: Deploy to Render

1. **Commit changes to GitHub:**
   ```bash
   git add .
   git commit -m "Add MongoDB Atlas integration"
   git push origin main
   ```

2. **Render will auto-deploy** when it sees the GitHub changes

3. **Check deployment logs** for:
   - ✅ "Connected to MongoDB Atlas successfully!"
   - ✅ "Default users created"
   - ✅ "Default food trucks created"

## 🎉 Step 6: Test the Migration

1. **Visit your health endpoint:** `https://your-app.onrender.com/api/health`
2. **Should show:**
   ```json
   {
     "status": "ok",
     "database": {
       "connected": true,
       "users": 2,
       "trucks": 3,
       "favorites": 0
     }
   }
   ```

3. **Register a new user** - it should persist after server restart!

## ✅ Success Indicators

- ✅ App connects to MongoDB Atlas
- ✅ Default data loads automatically
- ✅ User registration works and persists
- ✅ Food truck creation persists
- ✅ Favorites system works
- ✅ No more "data lost" issues!

## 🆘 Troubleshooting

**Connection Error:**
- Check your connection string format
- Verify password is correct (no special characters that need encoding)
- Ensure IP whitelist includes 0.0.0.0/0

**Deployment Error:**
- Check Render logs for specific error messages
- Verify MONGODB_URI environment variable is set
- Ensure mongoose is in package.json dependencies

**Data Not Persisting:**
- Check that all CRUD operations use MongoDB models
- Verify database connection is successful in logs

## 💰 Cost: $0 Forever!

- MongoDB Atlas M0 tier is completely free
- 512MB storage (plenty for your app)
- No time limits or hidden costs
- Can upgrade later if needed

---

**Ready to migrate? Follow these steps and your data persistence problem will be solved permanently!** 
# 🚀 Production Deployment Fixes

## 📋 Files to Update Before Deployment

### 1. **Fix Authentication Method** - `backend/src/controllers/authController.js`
Line 139, change:
```javascript
// OLD:
if (user && (await user.matchPassword(password))) {

// NEW:
if (user && (await user.comparePassword(password))) {
```

### 2. **Update CORS Settings** - `backend/src/server.js`
Replace `"https://food-truck-finder.netlify.app"` with YOUR actual Netlify URL on lines 27 and 42:
```javascript
const io = socketIo(server, {
  cors: {
    origin: [
      "http://localhost:3000", 
      "http://localhost:3001",
      "https://YOUR-APP-NAME.netlify.app"  // <- Replace this
    ],
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true
  }
});

// And also in the cors middleware:
app.use(cors({
  origin: [
    "http://localhost:3000", 
    "http://localhost:3001",
    "https://YOUR-APP-NAME.netlify.app"  // <- Replace this
  ],
  credentials: true
}));
```

### 3. **Environment Variables on Render**
Set these in your Render dashboard:
```
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/food-truck-tracker
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/food-truck-tracker
JWT_SECRET=your-production-secret-key-here
NODE_ENV=production
PORT=10000
FRONTEND_URL=https://YOUR-APP-NAME.netlify.app
```

### 4. **Environment Variables on Netlify**
Set these in your Netlify dashboard:
```
REACT_APP_API_URL=https://YOUR-BACKEND.onrender.com
REACT_APP_WEBSOCKET_URL=https://YOUR-BACKEND.onrender.com
```

## 🔧 Quick Fix Commands

Run these commands to apply all fixes and push to GitHub:

```bash
# 1. Fix the matchPassword error
cd backend
sed -i 's/user.matchPassword/user.comparePassword/g' src/controllers/authController.js

# 2. Commit all fixes
git add -A
git commit -m "Fix authentication and prepare for production deployment"

# 3. Push to GitHub
git push origin main
```

## ✅ Files Already Fixed:
- `backend/src/middleware/authMiddleware.js` - JWT token consistency ✅
- `backend/src/routes/events.js` - Auth middleware imports ✅
- `backend/src/routes/foodTrucks.js` - User ID references ✅

## 🚨 IMPORTANT: Before Pushing to GitHub

1. **Update YOUR Netlify URL** in `backend/src/server.js`
2. **Change JWT_SECRET** to a secure value in Render
3. **Ensure MongoDB Atlas allows Render's IPs** (or use 0.0.0.0/0)

## 📱 After Deployment

Your app will be available at:
- **Customer Portal**: https://YOUR-APP-NAME.netlify.app
- **Owner Dashboard**: https://YOUR-BACKEND.onrender.com/dashboard.html

## 🧪 Test Production Features:
1. Customer registration and login
2. Food truck owner login
3. GPS tracking (ensure HTTPS for geolocation)
4. WebSocket real-time updates
5. Social media integration 
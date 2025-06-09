# 🚀 Deployment Guide for Food Truck App

## 📋 Prerequisites
- Netlify account (for frontend)
- Render account (for backend)
- MongoDB Atlas account (for cloud database) or existing MongoDB URL

## 🎯 Overview
- **Frontend**: React app deployed on Netlify
- **Backend**: Node.js/Express API deployed on Render
- **Database**: MongoDB (Atlas or other cloud provider)

---

## 🔧 Backend Deployment (Render)

### 1. Environment Variables on Render
In your Render dashboard, set these environment variables:

```env
MONGO_URI=mongodb+srv://your-username:your-password@cluster.mongodb.net/food-truck-tracker
MONGODB_URI=mongodb+srv://your-username:your-password@cluster.mongodb.net/food-truck-tracker
JWT_SECRET=your-super-secure-jwt-secret-key-here
NODE_ENV=production
PORT=10000
FRONTEND_URL=https://your-app-name.netlify.app
```

### 2. Update CORS Configuration
Before deploying, update `backend/src/server.js` to include your Netlify domain:

```javascript
const io = socketIo(server, {
  cors: {
    origin: [
      "http://localhost:3000", 
      "http://localhost:3001",
      "https://your-app-name.netlify.app"  // <- Replace with your Netlify URL
    ],
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true
  }
});

app.use(cors({
  origin: [
    "http://localhost:3000", 
    "http://localhost:3001",
    "https://your-app-name.netlify.app"  // <- Replace with your Netlify URL
  ],
  credentials: true
}));
```

### 3. Deploy to Render
1. Push your code to GitHub
2. In Render dashboard:
   - Create New > Web Service
   - Connect your GitHub repo
   - Use these settings:
     - **Name**: food-truck-backend
     - **Root Directory**: backend
     - **Build Command**: `npm install`
     - **Start Command**: `npm start`
   - Add environment variables from step 1
   - Deploy!

---

## 🌐 Frontend Deployment (Netlify)

### 1. Environment Variables on Netlify
In Netlify dashboard > Site settings > Environment variables:

```env
REACT_APP_API_URL=https://food-truck-backend.onrender.com
REACT_APP_WEBSOCKET_URL=https://food-truck-backend.onrender.com
```

Replace `food-truck-backend` with your actual Render service name.

### 2. Build Settings on Netlify
- **Base directory**: `web-portal`
- **Build command**: `npm run build`
- **Publish directory**: `web-portal/build`

### 3. Deploy to Netlify
1. Push your code to GitHub
2. In Netlify dashboard:
   - Import from Git
   - Connect to GitHub
   - Select your repository
   - Configure build settings from step 2
   - Add environment variables from step 1
   - Deploy!

---

## ✅ Post-Deployment Checklist

### 1. Test Backend API
```bash
curl https://your-backend.onrender.com/test
```

### 2. Test WebSocket Connection
Open browser console on your Netlify app and check for:
- "Connected to WebSocket server" message
- No CORS errors

### 3. Verify Features
- [ ] Customer registration/login
- [ ] Food truck owner registration/login
- [ ] GPS tracking functionality
- [ ] Real-time updates via WebSocket
- [ ] Social media integration
- [ ] File uploads (if applicable)

### 4. Database Indexes (Important!)
Connect to your MongoDB and create these indexes for performance:

```javascript
// In MongoDB shell or Atlas
db.foodtrucks.createIndex({ "location.coordinates": "2dsphere" })
db.foodtrucks.createIndex({ "isActive": 1 })
db.foodtrucks.createIndex({ "cuisineType": 1 })
db.users.createIndex({ "email": 1 })
```

---

## 🐛 Common Issues & Solutions

### CORS Errors
- Double-check that your Netlify URL is added to CORS origins in backend
- Ensure credentials: true is set in both frontend and backend

### WebSocket Connection Failed
- Render may use a different URL format for WebSockets
- Try using `wss://` instead of `https://` for REACT_APP_WEBSOCKET_URL

### Authentication Issues
- Verify JWT_SECRET is the same in both development and production
- Check that Bearer token is being sent in Authorization header

### MongoDB Connection Issues
- Whitelist Render's IP addresses in MongoDB Atlas
- Or use 0.0.0.0/0 to allow all IPs (less secure)

---

## 🔒 Security Reminders

1. **Change JWT_SECRET** to a secure random string in production
2. **Use environment variables** - never commit secrets to Git
3. **Enable HTTPS** - Both Netlify and Render provide this by default
4. **Restrict CORS** to only your production domains
5. **Set up MongoDB user** with limited permissions

---

## 📊 Monitoring

### Render
- Monitor logs: Dashboard > Logs
- Set up health checks for uptime monitoring

### Netlify
- Check build logs for deployment issues
- Monitor function logs if using Netlify Functions

### MongoDB Atlas
- Enable performance monitoring
- Set up alerts for high usage

---

## 🎉 Success!
Once deployed, your app will be available at:
- **Frontend**: https://your-app-name.netlify.app
- **Backend API**: https://your-backend.onrender.com/api
- **Owner Dashboard**: https://your-backend.onrender.com/dashboard.html

Remember to update any hardcoded localhost URLs in your code! 
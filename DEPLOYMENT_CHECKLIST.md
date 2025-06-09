# 🚀 Food Truck App - Production Deployment Checklist

## ✅ Step 1: Update CORS Settings
Edit `backend/src/server.js` and replace `"https://YOUR-APP-NAME.netlify.app"` with your actual Netlify URL on lines 28 and 45.

## ✅ Step 2: Commit and Push to GitHub
```bash
# Add the CORS changes
git add backend/src/server.js

# Commit
git commit -m "Add production CORS settings"

# Push to GitHub (replace 'main' with your branch name if different)
git push origin main
```

## ✅ Step 3: Environment Variables on Render
Go to your Render dashboard → Your Service → Environment:

```
MONGO_URI=mongodb+srv://your-username:your-password@cluster.mongodb.net/food-truck-tracker
MONGODB_URI=mongodb+srv://your-username:your-password@cluster.mongodb.net/food-truck-tracker
JWT_SECRET=your-super-secure-production-secret-key
NODE_ENV=production
PORT=10000
FRONTEND_URL=https://your-app-name.netlify.app
```

## ✅ Step 4: Environment Variables on Netlify
Go to Netlify → Site settings → Environment variables:

```
REACT_APP_API_URL=https://your-backend-name.onrender.com
REACT_APP_WEBSOCKET_URL=https://your-backend-name.onrender.com
```

## ✅ Step 5: MongoDB Atlas Configuration
1. Go to MongoDB Atlas → Network Access
2. Add IP Address: `0.0.0.0/0` (allows all IPs - for production)
3. Or add Render's specific IPs for better security

## ✅ Step 6: Trigger Deployments
1. **Render**: Should auto-deploy when you push to GitHub
2. **Netlify**: Should auto-deploy when you push to GitHub
3. If not, manually trigger deploy in both dashboards

## 🧪 Step 7: Test Production Features

### Customer Portal Tests:
1. Visit: `https://your-app-name.netlify.app`
2. Register a new customer account
3. Login and access Profile & Settings
4. Search for food trucks
5. Add favorites

### Owner Dashboard Tests:
1. Visit: `https://your-backend-name.onrender.com/dashboard.html`
2. Login with test credentials
3. Start GPS tracking
4. Update menu items
5. Check real-time updates

### WebSocket Test:
1. Open browser console on customer portal
2. Should see: "Connected to WebSocket server"
3. Have owner start GPS tracking
4. Customer should see real-time updates

## 🐛 Common Issues & Solutions

### "CORS Error" in Console
- Double-check your Netlify URL in `backend/src/server.js`
- Ensure it includes `https://` and matches exactly
- Redeploy backend after changes

### "Cannot connect to WebSocket"
- Check REACT_APP_WEBSOCKET_URL in Netlify
- Try using `wss://` instead of `https://` if needed

### "Authentication Failed"
- Ensure JWT_SECRET is the same in development and production
- Check that all auth fixes were deployed

### "MongoDB Connection Failed"
- Verify MongoDB Atlas allows connections from Render
- Check MONGO_URI is correct and includes password

## 📊 Monitoring
- **Render Logs**: Dashboard → Logs
- **Netlify Build Logs**: Deploys → Click on deploy
- **MongoDB Atlas**: Monitoring → Real-Time

## 🎉 Success Indicators
- ✅ Backend API responds: `https://your-backend.onrender.com/test`
- ✅ Frontend loads without errors
- ✅ Users can register and login
- ✅ WebSocket shows "Connected" in console
- ✅ GPS tracking works over HTTPS

## 🔒 Security Reminders
1. Change JWT_SECRET to a secure value
2. Use environment variables for all secrets
3. Consider restricting MongoDB to specific IPs
4. Enable HTTPS redirect on Netlify
5. Set up monitoring alerts 
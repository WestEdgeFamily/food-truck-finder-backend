# 🚀 Deploy Your Food Truck Backend to Render

Follow these exact steps to get your backend live in the cloud:

## Step 1: Prepare Your Files ✅

Your backend files are ready:
- ✅ `backend/server.js` (configured for cloud deployment)
- ✅ `backend/package.json` (with correct start script)
- ✅ `backend/README.md` (documentation)
- ✅ `backend/.gitignore` (clean deployment)

## Step 2: Create GitHub Repository

### Option A: GitHub Desktop (Easiest)
1. Download GitHub Desktop from https://desktop.github.com/
2. Install and sign in to your GitHub account
3. Click "Create a New Repository on your hard drive"
4. Name: `food-truck-backend`
5. Location: Choose your `backend` folder
6. Click "Create Repository"
7. Click "Publish repository" to upload to GitHub

### Option B: GitHub Web (Manual)
1. Go to https://github.com and sign in
2. Click "New" to create repository
3. Name: `food-truck-backend`
4. Make it Public
5. Don't add README (you already have one)
6. Click "Create repository"
7. Upload all files from your `backend` folder

## Step 3: Deploy to Render

1. Go to https://render.com and sign up/sign in
2. Click "New +" → "Web Service"
3. Click "Connect account" → Select GitHub
4. Find and select your `food-truck-backend` repository
5. Configure deployment:
   - **Name**: `food-truck-api` (or whatever you want)
   - **Environment**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free

6. Click "Create Web Service"

## Step 4: Wait for Deployment (2-3 minutes)

You'll see logs like:
```
==> Building...
==> Installing dependencies
==> Starting service
🚚 Food Truck API Server running on port 10000
```

## Step 5: Get Your URL

Once deployed, you'll get a URL like:
`https://food-truck-api-abc123.onrender.com`

## Step 6: Test Your Deployment

Test these endpoints:
- Health: `https://your-url.onrender.com/api/health`
- Trucks: `https://your-url.onrender.com/api/trucks`

## Step 7: Update Flutter App

Edit `food_truck_mobile/lib/services/api_service.dart`:

```dart
// Replace with your actual Render URL
static const String baseUrl = 'https://your-actual-url.onrender.com/api';
```

## 🎉 You're Done!

Your backend is now live 24/7 and accessible worldwide!

## ⚠️ Important Notes

- **Free tier sleeps after 15 min** - First request might be slow
- **Keep the exact URL** - Don't use `food-truck-finder-api.onrender.com` (that doesn't exist)
- **Use HTTPS** - Render provides SSL automatically

## 🛠️ Troubleshooting

**Build fails?**
- Check that `package.json` has `"start": "node server.js"`
- Make sure all files are uploaded

**Service won't start?**
- Check Render logs for errors
- Ensure `server.js` uses `process.env.PORT`

**Can't connect?**
- Wait 30 seconds for service to warm up
- Check the exact URL in Render dashboard
- Make sure you're using HTTPS

**Need help?** Check the Render logs in your dashboard! 
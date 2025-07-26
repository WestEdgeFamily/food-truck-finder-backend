# 🚀 Simple Steps Before Building Your App

## 1️⃣ Commit Your Code Changes

Run this in your Food Truck App folder:
```cmd
commit_production_changes.bat
git push origin main
```

## 2️⃣ Set Up Firebase (10 minutes)

### A. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click **"Create a project"**
3. Name: `food-truck-finder`
4. Enable Google Analytics: **Yes**
5. Click **Create**

### B. Add Your Android App
1. Click the **Android icon** to add an Android app
2. Fill in:
   - Package name: `com.foodtrucks.app.food_truck_app`
   - App nickname: `Food Truck Finder`
   - SHA-1: `03:01:BD:64:5A:BD:D6:63:61:FD:7A:A1:52:C1:27:43:09:74:2E:F7`
3. Click **Register app**

### C. Download Config File
1. Download `google-services.json`
2. Copy it to: `food_truck_mobile\android\app\`

### D. Skip the SDK setup steps in Firebase
Just click **Next** → **Next** → **Continue to console**
(We already added the Firebase packages)

## 3️⃣ Quick Firebase Fix for Gradle

Since you're using Kotlin gradle files, add this manually:

Edit `food_truck_mobile\android\app\build.gradle`:
At the very bottom, add:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## 4️⃣ Build Your Production App

```cmd
cd food_truck_mobile
flutter clean
flutter build appbundle --release
```

## 5️⃣ That's It!

Your AAB file will be at:
`build\app\outputs\bundle\release\app-release.aab`

## ❓ What if Firebase doesn't work?

Don't worry! The app will still work fine. Firebase is just for:
- Crash reports (nice to have)
- Analytics (nice to have)

The core app functionality (maps, food trucks, etc.) will work without Firebase.

## 📱 Ready to Upload

Once built, you can upload the AAB to Google Play Console!
# 🔥 Firebase Setup Guide for Food Truck App

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Create a project"**
3. Name it: `food-truck-finder` (or similar)
4. Enable Google Analytics (optional but recommended)
5. Click **Create Project**

## Step 2: Add Android App

1. In Firebase Console, click **"Add app"** → **Android**
2. Fill in:
   - **Package name**: `com.foodtrucks.app.food_truck_app`
   - **App nickname**: Food Truck Finder
   - **SHA-1**: `03:01:BD:64:5A:BD:D6:63:61:FD:7A:A1:52:C1:27:43:09:74:2E:F7`
3. Click **Register app**

## Step 3: Download Config File

1. Download `google-services.json`
2. Place it in: `food_truck_mobile/android/app/`
   ```
   food_truck_mobile/
   └── android/
       └── app/
           ├── google-services.json  ← HERE
           ├── build.gradle
           └── src/
   ```

## Step 4: Update Android Build Files

### 4.1 Project-level build.gradle
File: `food_truck_mobile/android/build.gradle`

Add this to the dependencies section:
```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 4.2 App-level build.gradle
File: `food_truck_mobile/android/app/build.gradle`

Add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 5: Enable Firebase Services

In Firebase Console, go to each service and enable:

### 5.1 Crashlytics
1. Click **"Crashlytics"** in left menu
2. Click **"Enable Crashlytics"**
3. Follow setup instructions

### 5.2 Analytics
1. Click **"Analytics"** in left menu
2. It should already be enabled
3. Configure events as needed

### 5.3 Performance Monitoring (Optional)
1. Click **"Performance"** in left menu
2. Click **"Get started"**

## Step 6: Add iOS App (Optional)

If building for iOS:
1. Click **"Add app"** → **iOS**
2. Bundle ID: `com.foodtrucks.app.foodTruckApp`
3. Download `GoogleService-Info.plist`
4. Place in `food_truck_mobile/ios/Runner/`

## Step 7: Test Firebase Integration

Run this test build:
```bash
cd food_truck_mobile
flutter clean
flutter pub get
flutter run --debug
```

Check Firebase Console for:
- First app open event in Analytics
- No crashes in Crashlytics

## Step 8: Production Build with Firebase

```bash
flutter build appbundle --release \
  --dart-define=ENABLE_CRASHLYTICS=true \
  --dart-define=ENABLE_ANALYTICS=true
```

## ⚠️ Important Notes

1. **Don't commit** `google-services.json` to public repos
2. **Add to .gitignore**:
   ```
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ```

3. **For CI/CD**: Store these files as secrets and download during build

## 🧪 Verify Firebase is Working

1. **Analytics**: Check Realtime view in Firebase Console
2. **Crashlytics**: Force a test crash:
   ```dart
   // Add temporarily to test
   FirebaseCrashlytics.instance.crash();
   ```

## 📱 Firebase Features Now Available

- ✅ Crash reporting
- ✅ User analytics
- ✅ Performance monitoring
- ✅ Remote config (if needed)
- ✅ Cloud messaging (for push notifications)

---

**Need Help?** Check Firebase documentation or run:
```
flutter doctor
firebase --version
```
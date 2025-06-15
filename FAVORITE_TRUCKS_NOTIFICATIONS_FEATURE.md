# Favorite Food Truck Notifications Feature

## Overview
This feature allows customers to:
1. Mark food trucks as favorites
2. Set a notification radius (1-50 miles)
3. Receive push notifications when favorite food trucks come within their set distance
4. Monitor location tracking status and manually check for nearby favorites

## Features Implemented

### 1. Notification Service (`lib/services/notification_service.dart`)
- **Flutter Local Notifications**: Uses `flutter_local_notifications` for cross-platform notifications
- **Smart Notification Management**: Prevents spam by tracking already notified trucks (30-minute cooldown)
- **Settings Integration**: Respects user notification preferences from settings
- **Distance Calculation**: Converts miles to meters and calculates precise distances

**Key Methods:**
- `initialize()`: Sets up notification channels
- `showFavoriteTruckNearbyNotification()`: Shows notification for nearby favorite truck
- `checkFavoriteTrucksNearby()`: Checks all favorite trucks against user location
- `requestPermissions()`: Handles Android notification permissions

### 2. Location Monitoring Provider (`lib/providers/location_monitoring_provider.dart`)
- **Background Monitoring**: Periodic location checks every 5 minutes
- **Battery Efficient**: Uses Timer-based approach rather than continuous GPS
- **Provider Pattern**: Integrates with Flutter's Provider for state management
- **Manual Checks**: Allows users to manually trigger location checks

**Key Methods:**
- `startLocationMonitoring()`: Begins background location tracking
- `stopLocationMonitoring()`: Stops tracking to save battery
- `checkNowForNearbyTrucks()`: Manual check for nearby favorites
- `getLastCheckText()`: Human-readable last check time

### 3. Enhanced Settings Screen
- **Location Monitoring Status**: Shows active/inactive status and last check time
- **Manual Check Button**: Users can manually trigger location checks
- **Settings Integration**: All existing notification settings work with new feature
- **Real-time Updates**: Uses Consumer widgets to show live status

### 4. App Integration
- **Main App**: Added LocationMonitoringProvider to app providers
- **Customer Screen**: Automatic initialization and lifecycle management  
- **Background Handling**: Proper cleanup on app pause/resume
- **Permission Handling**: Comprehensive location and notification permissions

## User Experience

### Settings Available:
1. **Enable Notifications**: Master switch for all notifications
2. **Location-Based Notifications**: Enable location-aware features
3. **Favorite Trucks Nearby**: Specific toggle for favorite truck notifications
4. **Notification Radius**: Slider from 1-50 miles (default: 20 miles)

### Notification Behavior:
- **Smart Timing**: Only notifies once per truck per 30 minutes
- **Rich Notifications**: Shows truck name, distance, and cuisine types
- **Tap to Open**: Notifications can be enhanced to open truck detail screen
- **Respectful**: Follows all user preference settings

### Location Monitoring:
- **Automatic Start**: Begins when app launches and user is logged in
- **Background Safe**: Continues checking even when app is backgrounded
- **Battery Conscious**: Checks every 5 minutes, not continuously
- **Permission Aware**: Only works when proper permissions are granted

## Technical Implementation

### Dependencies Added:
```yaml
flutter_local_notifications: ^16.3.2
```

### Android Permissions Added:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## Files Created/Modified

### New Files:
- `lib/services/notification_service.dart` - Handles all notification logic
- `lib/providers/location_monitoring_provider.dart` - Background location monitoring

### Modified Files:
- `lib/main.dart` - Added LocationMonitoringProvider to app
- `lib/screens/customer/customer_main_screen.dart` - Added lifecycle management
- `lib/screens/customer/settings_screen.dart` - Added monitoring status UI
- `lib/screens/customer/customer_profile_screen.dart` - Fixed navigation link
- `food_truck_mobile/pubspec.yaml` - Added notification dependency
- `food_truck_mobile/android/app/src/main/AndroidManifest.xml` - Added permissions

## Testing the Feature

### To Test:
1. **Set Up Favorites**: Add some food trucks to favorites
2. **Configure Settings**: 
   - Enable all notification settings
   - Set a small notification radius (1-2 miles)
3. **Manual Check**: Use "Check Now" button in settings
4. **Location Simulation**: Use emulator location tools to simulate movement
5. **Background Test**: Put app in background and check if notifications still work

### Expected Behavior:
- App requests location and notification permissions on first launch
- Location monitoring starts automatically for logged-in customers
- Settings screen shows "Location monitoring active" when working
- Manual checks trigger immediate location/favorites comparison
- Notifications appear when favorite trucks are within set radius
- No duplicate notifications for same truck within 30 minutes

## Future Enhancements

### Possible Improvements:
1. **Notification Actions**: Add "View Truck" and "Get Directions" buttons
2. **Smart Scheduling**: Only check during business hours or user's active times  
3. **Geofencing**: Use more efficient geofencing APIs for better battery life
4. **Push Notifications**: Integrate with Firebase for server-side notifications
5. **Notification Categories**: Different notification types (new truck, favorite nearby, special offers)
6. **Analytics**: Track which notifications lead to app opens or orders

## Troubleshooting

### Common Issues:
1. **No Notifications**: Check if all permissions are granted and settings enabled
2. **Battery Drain**: Monitoring is designed to be efficient, but can be disabled in settings
3. **Inaccurate Distance**: Ensure location permissions include "precise location"
4. **Background Issues**: Android's battery optimization may interfere with background location

### Debug Information:
- Settings screen shows last check time and monitoring status
- Console logs track location checks and notification triggers
- User ID shown in settings for debugging API calls 
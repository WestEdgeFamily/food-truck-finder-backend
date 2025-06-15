import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_truck.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Set<String> _notifiedTrucks = {}; // Track which trucks we've already notified about

  Future<void> initialize() async {
    if (_isInitialized) return;

    // TODO: Temporarily disabled due to build issues
    // const AndroidInitializationSettings initializationSettingsAndroid =
    //     AndroidInitializationSettings('@mipmap/ic_launcher');

    // const InitializationSettings initializationSettings =
    //     InitializationSettings(
    //   android: initializationSettingsAndroid,
    // );

    // await _flutterLocalNotificationsPlugin.initialize(
    //   initializationSettings,
    //   onDidReceiveNotificationResponse: _onNotificationTapped,
    // );

    _isInitialized = true;
  }

  void _onNotificationTapped(dynamic notificationResponse) {
    // Handle notification tap
    debugPrint('Notification tapped: $notificationResponse');
    // TODO: Navigate to specific food truck detail screen
  }

  Future<bool> requestPermissions() async {
    // TODO: Temporarily disabled due to build issues
    // final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    //     _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
    //         AndroidFlutterLocalNotificationsPlugin>();

    // if (androidImplementation != null) {
    //   return await androidImplementation.requestPermission() ?? false;
    // }
    return true; // Temporarily return true
  }

  Future<void> showFavoriteTruckNearbyNotification(FoodTruck truck, double distance) async {
    // Check if notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    final locationNotifications = prefs.getBool('location_notifications') ?? true;
    final favoritesNearby = prefs.getBool('favorites_nearby') ?? true;

    if (!notificationsEnabled || !locationNotifications || !favoritesNearby) {
      return;
    }

    // Check if we've already notified about this truck recently
    if (_notifiedTrucks.contains(truck.id)) {
      return;
    }

    // Add to notified trucks and remove after 30 minutes
    _notifiedTrucks.add(truck.id);
    Future.delayed(const Duration(minutes: 30), () {
      _notifiedTrucks.remove(truck.id);
    });

    // TODO: Temporarily disabled actual notifications due to build issues
    // Will be re-enabled in next update
    final distanceText = distance < 1000 
        ? '${distance.round()}m away' 
        : '${(distance / 1000).toStringAsFixed(1)}km away';

    debugPrint('🚚 NOTIFICATION: ${truck.name} is nearby! ($distanceText)');
    
    // const AndroidNotificationDetails androidNotificationDetails =
    //     AndroidNotificationDetails(
    //   'favorites_nearby',
    //   'Favorite Trucks Nearby',
    //   channelDescription: 'Notifications when favorite food trucks are nearby',
    //   importance: Importance.high,
    //   priority: Priority.high,
    //   icon: '@mipmap/ic_launcher',
    // );

    // const NotificationDetails notificationDetails =
    //     NotificationDetails(android: androidNotificationDetails);

    // await _flutterLocalNotificationsPlugin.show(
    //   truck.hashCode, // Use truck's hashCode as unique ID
    //   '🚚 ${truck.name} is nearby!',
    //   '$distanceText • ${truck.cuisineTypes.join(', ')}',
    //   notificationDetails,
    //   payload: truck.id,
    // );
  }

  Future<void> checkFavoriteTrucksNearby(
    Position userLocation,
    List<FoodTruck> favoriteTrucks,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationRadius = prefs.getDouble('notification_radius') ?? 20.0;
    final radiusInMeters = notificationRadius * 1609.34; // Convert miles to meters

    for (final truck in favoriteTrucks) {
      if (truck.latitude != null && truck.longitude != null) {
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          truck.latitude!,
          truck.longitude!,
        );

        if (distance <= radiusInMeters) {
          await showFavoriteTruckNearbyNotification(truck, distance);
        }
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    // TODO: Temporarily disabled
    // await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    // TODO: Temporarily disabled
    // await _flutterLocalNotificationsPlugin.cancel(id);
  }

  void clearNotifiedTrucks() {
    _notifiedTrucks.clear();
  }
} 
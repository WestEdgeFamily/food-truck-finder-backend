import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/food_truck.dart';
import '../services/notification_service.dart';
import 'location_provider.dart';
import 'favorites_provider.dart';

class LocationMonitoringProvider extends ChangeNotifier {
  static final LocationMonitoringProvider _instance = LocationMonitoringProvider._internal();
  factory LocationMonitoringProvider() => _instance;
  LocationMonitoringProvider._internal();

  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  bool _isMonitoring = false;
  Position? _lastPosition;
  DateTime? _lastCheck;
  
  final NotificationService _notificationService = NotificationService();

  bool get isMonitoring => _isMonitoring;
  Position? get lastPosition => _lastPosition;
  DateTime? get lastCheck => _lastCheck;

  Future<void> initialize() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  /// Start monitoring user location for favorite trucks
  Future<void> startLocationMonitoring({
    required LocationProvider locationProvider,
    required FavoritesProvider favoritesProvider,
    required String userId,
  }) async {
    if (_isMonitoring) return;

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    final locationNotifications = prefs.getBool('location_notifications') ?? true;
    final favoritesNearby = prefs.getBool('favorites_nearby') ?? true;

    if (!notificationsEnabled || !locationNotifications || !favoritesNearby) {
      debugPrint('Location monitoring disabled in settings');
      return;
    }

    // Check if location permission is granted
    if (!locationProvider.permissionGranted) {
      final granted = await locationProvider.requestLocationPermission();
      if (!granted) {
        debugPrint('Location permission not granted');
        return;
      }
    }

    _isMonitoring = true;
    notifyListeners();

    // Start periodic location monitoring (every 5 minutes)
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkLocationAndNotify(locationProvider, favoritesProvider, userId);
    });

    // Also check immediately
    await _checkLocationAndNotify(locationProvider, favoritesProvider, userId);

    debugPrint('Location monitoring started');
  }

  /// Stop monitoring user location
  void stopLocationMonitoring() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    _locationTimer = null;
    _positionStream = null;
    _isMonitoring = false;
    _lastPosition = null;
    _lastCheck = null;
    
    notifyListeners();
    debugPrint('Location monitoring stopped');
  }

  /// Check current location and notify about nearby favorite trucks
  Future<void> _checkLocationAndNotify(
    LocationProvider locationProvider,
    FavoritesProvider favoritesProvider,
    String userId,
  ) async {
    try {
      // Get current location
      await locationProvider.getCurrentLocation();
      
      if (locationProvider.currentPosition == null) {
        debugPrint('Could not get current location');
        return;
      }

      _lastPosition = locationProvider.currentPosition;
      _lastCheck = DateTime.now();
      notifyListeners();

      // Load user's favorites if not already loaded
      if (favoritesProvider.favorites.isEmpty) {
        await favoritesProvider.loadFavorites(userId);
      }

      // Check for nearby favorite trucks
      if (favoritesProvider.favorites.isNotEmpty) {
        await _notificationService.checkFavoriteTrucksNearby(
          locationProvider.currentPosition!,
          favoritesProvider.favorites,
        );
      }

      debugPrint('Location check completed at ${_lastCheck}');
    } catch (e) {
      debugPrint('Error during location monitoring: $e');
    }
  }

  /// Manual check for nearby favorite trucks
  Future<void> checkNowForNearbyTrucks({
    required LocationProvider locationProvider,
    required FavoritesProvider favoritesProvider,
    required String userId,
  }) async {
    await _checkLocationAndNotify(locationProvider, favoritesProvider, userId);
  }

  /// Get formatted last check time
  String? getLastCheckText() {
    if (_lastCheck == null) return null;
    
    final now = DateTime.now();
    final difference = now.difference(_lastCheck!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  /// Check if location monitoring should be active based on settings
  Future<bool> shouldMonitorLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool('notifications_enabled') ?? true) &&
           (prefs.getBool('location_notifications') ?? true) &&
           (prefs.getBool('favorites_nearby') ?? true);
  }

  @override
  void dispose() {
    stopLocationMonitoring();
    super.dispose();
  }
} 
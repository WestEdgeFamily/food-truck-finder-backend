import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer => _observer;

  void initialize() {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // User Events
  Future<void> logLogin(String method) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> setUserId(String? userId) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.setUserId(userId: userId);
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Food Truck Events
  Future<void> logViewFoodTruck({
    required String truckId,
    required String truckName,
    String? cuisineType,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'view_food_truck',
      parameters: {
        'truck_id': truckId,
        'truck_name': truckName,
        if (cuisineType != null) 'cuisine_type': cuisineType,
      },
    );
  }

  Future<void> logAddToFavorites({
    required String truckId,
    required String truckName,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'add_to_favorites',
      parameters: {
        'truck_id': truckId,
        'truck_name': truckName,
      },
    );
  }

  Future<void> logRemoveFromFavorites({
    required String truckId,
    required String truckName,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'remove_from_favorites',
      parameters: {
        'truck_id': truckId,
        'truck_name': truckName,
      },
    );
  }

  Future<void> logWriteReview({
    required String truckId,
    required int rating,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'write_review',
      parameters: {
        'truck_id': truckId,
        'rating': rating,
      },
    );
  }

  // Location Events
  Future<void> logLocationUpdate({
    required double latitude,
    required double longitude,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'location_update',
      parameters: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<void> logMapView() async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(name: 'view_map');
  }

  // Owner Events
  Future<void> logUpdateMenu({
    required String truckId,
    required int itemCount,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'update_menu',
      parameters: {
        'truck_id': truckId,
        'item_count': itemCount,
      },
    );
  }

  Future<void> logUpdateSchedule({
    required String truckId,
    required String scheduleType,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'update_schedule',
      parameters: {
        'truck_id': truckId,
        'schedule_type': scheduleType,
      },
    );
  }

  Future<void> logPosConnection({
    required String posSystem,
    required bool success,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'pos_connection',
      parameters: {
        'pos_system': posSystem,
        'success': success,
      },
    );
  }

  Future<void> logSocialMediaPost({
    required String platform,
    required String postType,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: 'social_media_post',
      parameters: {
        'platform': platform,
        'post_type': postType,
      },
    );
  }

  // Search Events
  Future<void> logSearch({
    required String searchTerm,
    required int resultsCount,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logSearch(
      searchTerm: searchTerm,
      numberOfResults: resultsCount,
    );
  }

  // Screen Views
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // App Events
  Future<void> logAppOpen() async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logAppOpen();
  }

  // Custom Events
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!AppConfig.enableAnalytics) return;
    
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}

// Singleton getter
final analyticsService = AnalyticsService();
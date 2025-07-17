import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static const String _cachePrefix = 'ft_cache_';
  static const String _cacheTimePrefix = 'ft_cache_time_';
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  
  // Cache keys
  static const String foodTrucksKey = 'food_trucks';
  static const String userDataKey = 'user_data';
  static const String favoritesKey = 'favorites';
  static const String menuKey = 'menu_';
  static const String truckDetailKey = 'truck_';
  
  // Save data to cache with timestamp
  static Future<void> saveToCache(String key, dynamic data, {Duration? duration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timeKey = '$_cacheTimePrefix$key';
      
      // Save data
      await prefs.setString(cacheKey, json.encode(data));
      
      // Save timestamp
      final expirationTime = DateTime.now().add(duration ?? _defaultCacheDuration);
      await prefs.setInt(timeKey, expirationTime.millisecondsSinceEpoch);
      
      debugPrint('💾 Cached data for key: $key');
    } catch (e) {
      debugPrint('❌ Cache save error: $e');
    }
  }
  
  // Get data from cache if not expired
  static Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timeKey = '$_cacheTimePrefix$key';
      
      // Check if cache exists
      if (!prefs.containsKey(cacheKey) || !prefs.containsKey(timeKey)) {
        debugPrint('🔍 No cache found for key: $key');
        return null;
      }
      
      // Check if cache is expired
      final expirationTime = prefs.getInt(timeKey) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        debugPrint('⏰ Cache expired for key: $key');
        await clearCache(key);
        return null;
      }
      
      // Return cached data
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        debugPrint('✅ Cache hit for key: $key');
        return json.decode(cachedData);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Cache read error: $e');
      return null;
    }
  }
  
  // Clear specific cache
  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
      await prefs.remove('$_cacheTimePrefix$key');
      debugPrint('🗑️ Cleared cache for key: $key');
    } catch (e) {
      debugPrint('❌ Cache clear error: $e');
    }
  }
  
  // Clear all app cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimePrefix)) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('🗑️ Cleared all app cache');
    } catch (e) {
      debugPrint('❌ Clear all cache error: $e');
    }
  }
  
  // Get cache size
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final data = prefs.getString(key);
          if (data != null) {
            totalSize += data.length;
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ Get cache size error: $e');
      return 0;
    }
  }
  
  // Cache food trucks list
  static Future<void> cacheFoodTrucks(List<dynamic> trucks) async {
    await saveToCache(foodTrucksKey, trucks, duration: const Duration(minutes: 30));
  }
  
  // Get cached food trucks
  static Future<List<dynamic>?> getCachedFoodTrucks() async {
    final cached = await getFromCache(foodTrucksKey);
    if (cached is List) {
      return cached;
    }
    return null;
  }
  
  // Cache truck details
  static Future<void> cacheTruckDetail(String truckId, Map<String, dynamic> truckData) async {
    await saveToCache('$truckDetailKey$truckId', truckData, duration: const Duration(hours: 2));
  }
  
  // Get cached truck details
  static Future<Map<String, dynamic>?> getCachedTruckDetail(String truckId) async {
    final cached = await getFromCache('$truckDetailKey$truckId');
    if (cached is Map<String, dynamic>) {
      return cached;
    }
    return null;
  }
  
  // Cache menu items
  static Future<void> cacheMenu(String truckId, List<dynamic> menu) async {
    await saveToCache('$menuKey$truckId', menu, duration: const Duration(hours: 1));
  }
  
  // Get cached menu
  static Future<List<dynamic>?> getCachedMenu(String truckId) async {
    final cached = await getFromCache('$menuKey$truckId');
    if (cached is List) {
      return cached;
    }
    return null;
  }
  
  // Cache user data
  static Future<void> cacheUserData(Map<String, dynamic> userData) async {
    await saveToCache(userDataKey, userData, duration: const Duration(days: 7));
  }
  
  // Get cached user data
  static Future<Map<String, dynamic>?> getCachedUserData() async {
    final cached = await getFromCache(userDataKey);
    if (cached is Map<String, dynamic>) {
      return cached;
    }
    return null;
  }
  
  // Clear user-related cache (on logout)
  static Future<void> clearUserCache() async {
    await clearCache(userDataKey);
    await clearCache(favoritesKey);
    debugPrint('🗑️ Cleared user cache');
  }
} 
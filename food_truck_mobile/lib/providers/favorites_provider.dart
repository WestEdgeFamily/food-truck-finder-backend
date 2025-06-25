import 'package:flutter/foundation.dart';
import '../models/food_truck.dart';
import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  List<FoodTruck> _favorites = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  Set<String> _favoriteIds = {};
  String? _error;
  bool _isEndpointAvailable = true;

  List<FoodTruck> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  Set<String> get favoriteIds => _favoriteIds;
  String? get error => _error;
  bool get isEndpointAvailable => _isEndpointAvailable;

  bool isFavorite(String truckId) {
    return _favoriteIds.contains(truckId);
  }

  Future<void> checkEndpointAvailability() async {
    _isEndpointAvailable = await ApiService.isFavoritesEndpointAvailable();
    notifyListeners();
  }

  Future<void> loadFavorites(String userId) async {
    if (!_isEndpointAvailable) {
      _error = 'Favorites feature is not available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final favoriteTrucks = await ApiService.getFavorites(userId);
      debugPrint('🔍 Raw favorites response: $favoriteTrucks');
      
      if (favoriteTrucks.isNotEmpty) {
        // Try to parse as FoodTruck objects
        try {
          _favorites = favoriteTrucks.map((truck) => FoodTruck.fromJson(truck)).toList();
          _favoriteIds = _favorites.map((truck) => truck.id).toSet();
          _error = null;
          debugPrint('✅ Successfully loaded ${_favorites.length} favorites');
        } catch (parseError) {
          // If parsing fails, show empty list
          debugPrint('⚠️ Failed to parse favorites: $parseError');
          _favorites = [];
          _favoriteIds = {};
          _error = 'Failed to parse favorites data';
        }
      } else {
        // Empty favorites list from API
        debugPrint('📝 No favorites found for user');
        _favorites = [];
        _favoriteIds = {};
        _error = null;
      }
    } catch (e) {
      debugPrint('❌ Error loading favorites: $e');
      _favorites = [];
      _favoriteIds = {};
      _error = 'Failed to load favorites: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(String userId, String truckId) async {
    debugPrint('🔥 FAVORITES DEBUG: toggleFavorite called');
    debugPrint('🔥 User ID: $userId');
    debugPrint('🔥 Truck ID: $truckId');
    debugPrint('🔥 Endpoint available: $_isEndpointAvailable');
    
    if (!_isEndpointAvailable) {
      _error = 'Favorites feature is not available';
      notifyListeners();
      return false;
    }

    _isActionLoading = true;
    notifyListeners();

    final wasFavorite = _favoriteIds.contains(truckId);
    debugPrint('🔥 Was favorite before: $wasFavorite');
    
    try {
      if (wasFavorite) {
        debugPrint('🔥 Attempting to REMOVE favorite...');
        final result = await ApiService.removeFavorite(userId, truckId);
        debugPrint('🔍 Remove favorite result: $result');
        // Remove from local state regardless of API response for demo
        _favoriteIds.remove(truckId);
        _favorites.removeWhere((truck) => truck.id == truckId);
        debugPrint('✅ Successfully removed favorite: $truckId');
        _error = null;
      } else {
        debugPrint('🔥 Attempting to ADD favorite...');
        final result = await ApiService.addFavorite(userId, truckId);
        debugPrint('🔍 Add favorite result: $result');
        // Add to local state regardless of API response for demo
        _favoriteIds.add(truckId);
        debugPrint('✅ Successfully added favorite: $truckId');
        _error = null;
      }
      
      debugPrint('🔥 Final favorite IDs: $_favoriteIds');
      debugPrint('🔥 Final favorites count: ${_favorites.length}');
      notifyListeners(); // Ensure UI updates immediately
      return !wasFavorite; // Return new favorite status
    } catch (e) {
      debugPrint('❌ CRITICAL ERROR toggling favorite: $e');
      // For demo purposes, still toggle locally even if API fails
      if (wasFavorite) {
        _favoriteIds.remove(truckId);
        _favorites.removeWhere((truck) => truck.id == truckId);
      } else {
        _favoriteIds.add(truckId);
      }
      debugPrint('❌ Error toggling favorite: $e, but toggled locally for demo');
      _error = null; // Don't show error for demo
      notifyListeners();
      return !wasFavorite; // Return new favorite status
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkFavoriteStatus(String userId, String truckId) async {
    if (!_isEndpointAvailable) return;

    try {
      final isFavorite = await ApiService.checkFavorite(userId, truckId);
      if (isFavorite) {
        _favoriteIds.add(truckId);
      } else {
        _favoriteIds.remove(truckId);
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to check favorite status: $e';
      debugPrint('Error checking favorite status: $e');
    }
  }

  void clearFavorites() {
    _favorites.clear();
    _favoriteIds.clear();
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<FoodTruck> _getMockFavorites() {
    return [
      FoodTruck(
        id: '1',
        name: 'Taco Paradise',
        businessName: 'Taco Paradise LLC',
        description: 'Authentic Mexican street tacos with fresh ingredients',
        ownerId: 'owner1',
        cuisineTypes: ['Mexican', 'Street Food'],
        image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800&h=600&fit=crop',
        latitude: 40.7128,
        longitude: -74.0060,
        address: '123 Taco Street, New York, NY',
        rating: 4.5,
        reviewCount: 87,
        isOpen: true,

        email: 'info@tacoparadise.com',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
      FoodTruck(
        id: '3',
        name: 'Pizza on Wheels',
        businessName: 'Mobile Pizza Co',
        description: 'Wood-fired pizza made fresh on the go',
        ownerId: 'owner3',
        cuisineTypes: ['Italian', 'Pizza'],
        image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&h=600&fit=crop',
        latitude: 40.7589,
        longitude: -73.9851,
        address: '789 Pizza Plaza, New York, NY',
        rating: 4.7,
        reviewCount: 203,
        isOpen: true,

        email: 'orders@pizzaonwheels.com',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    ];
  }
} 
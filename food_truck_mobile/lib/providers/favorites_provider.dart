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
      
      if (favoriteTrucks.isEmpty) {
        _error = 'API returned empty favorites list. Check backend connection.';
        _favorites = [];
        _favoriteIds = {};
      } else {
        // Try to parse as FoodTruck objects
        try {
          _favorites = favoriteTrucks.map((truck) => FoodTruck.fromJson(truck)).toList();
          _favoriteIds = _favorites.map((truck) => truck.id).toSet();
          _error = null;
          debugPrint('✅ Successfully loaded ${_favorites.length} favorites');
        } catch (parseError) {
          // If parsing fails, maybe we just got IDs
          _error = 'Got favorites data but failed to parse: $parseError. Raw data: $favoriteTrucks';
          _favorites = [];
          _favoriteIds = {};
        }
      }
    } catch (e) {
      _error = 'API Error: $e';
      debugPrint('❌ Error loading favorites: $e');
      _favorites = [];
      _favoriteIds = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(String userId, String truckId) async {
    if (!_isEndpointAvailable) {
      _error = 'Favorites feature is not available';
      notifyListeners();
      return false;
    }

    _isActionLoading = true;
    notifyListeners();

    final wasFavorite = _favoriteIds.contains(truckId);
    
    try {
      if (wasFavorite) {
        final result = await ApiService.removeFavorite(userId, truckId);
        debugPrint('🔍 Remove favorite result: $result');
        if (result['success'] == true) {
          _favoriteIds.remove(truckId);
          _favorites.removeWhere((truck) => truck.id == truckId);
          debugPrint('✅ Successfully removed favorite: $truckId');
        } else {
          _error = 'Remove failed: ${result['message']}';
        }
      } else {
        final result = await ApiService.addFavorite(userId, truckId);
        debugPrint('🔍 Add favorite result: $result');
        if (result['success'] == true) {
          _favoriteIds.add(truckId);
          debugPrint('✅ Successfully added favorite: $truckId');
          _error = null;
        } else {
          _error = 'Add failed: ${result['message']}';
        }
      }
      
      notifyListeners(); // Ensure UI updates immediately
      return !wasFavorite; // Return new favorite status
    } catch (e) {
      _error = 'Toggle Error: $e';
      debugPrint('❌ Error toggling favorite: $e');
      return wasFavorite; // Return original status on error
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
} 
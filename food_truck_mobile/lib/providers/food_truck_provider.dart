import 'package:flutter/foundation.dart';
import '../models/food_truck.dart';
import '../services/api_service.dart';

class FoodTruckProvider extends ChangeNotifier {
  List<FoodTruck> _foodTrucks = [];
  List<FoodTruck> _filteredTrucks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  List<String> _selectedCuisines = [];

  List<FoodTruck> get foodTrucks => _filteredTrucks;
  List<FoodTruck> get allFoodTrucks => _foodTrucks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<String> get selectedCuisines => _selectedCuisines;

  Future<void> loadFoodTrucks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trucks = await ApiService.getFoodTrucks();
      _foodTrucks = trucks.map((json) => FoodTruck.fromJson(json)).toList();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Error loading food trucks: $e';
      debugPrint('Food truck loading error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FoodTruck?> getFoodTruckById(String id) async {
    try {
      final truckData = await ApiService.getFoodTruckById(id);
      return FoodTruck.fromJson(truckData);
    } catch (e) {
      debugPrint('Error loading food truck $id: $e');
      return null;
    }
  }

  void searchTrucks(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByCuisines(List<String> cuisines) {
    _selectedCuisines = cuisines;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTrucks = _foodTrucks.where((truck) {
      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = truck.name.toLowerCase().contains(query) ||
            truck.description.toLowerCase().contains(query) ||
            truck.businessName.toLowerCase().contains(query);
      }

      // Cuisine filter
      bool matchesCuisine = true;
      if (_selectedCuisines.isNotEmpty) {
        matchesCuisine = truck.cuisineTypes.any((cuisine) => 
            _selectedCuisines.contains(cuisine));
      }

      return matchesSearch && matchesCuisine;
    }).toList();
  }

  List<String> get availableCuisines {
    final cuisines = <String>{};
    for (final truck in _foodTrucks) {
      cuisines.addAll(truck.cuisineTypes);
    }
    return cuisines.toList()..sort();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCuisines = [];
    _applyFilters();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // For food truck owners
  Future<bool> updateTruckLocation(String truckId, double latitude, double longitude, String? address) async {
    try {
      await ApiService.updateTruckLocation(truckId, latitude, longitude, address);
      
      // Update local data
      final truckIndex = _foodTrucks.indexWhere((truck) => truck.id == truckId);
      if (truckIndex != -1) {
        _foodTrucks[truckIndex] = _foodTrucks[truckIndex].copyWith(
          latitude: latitude,
          longitude: longitude,
          address: address,
          lastUpdated: DateTime.now(),
        );
        _applyFilters();
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating truck location: $e');
      return false;
    }
  }
} 
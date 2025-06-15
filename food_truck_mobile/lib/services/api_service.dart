import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Updated to use live cloud backend!
  static const String baseUrl = 'https://food-truck-finder-api.onrender.com/api';
  // For local development (testing favorites):
  // static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Login API error: $e');
      throw Exception('Network error during login');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Registration API error: $e');
      throw Exception('Network error during registration');
    }
  }

  // Favorites API methods
  static Future<bool> isFavoritesEndpointAvailable() async {
    try {
      final url = '$baseUrl/health';
      debugPrint('🔍 Checking API health: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint('🔍 Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ API health check error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getFavorites(String userId) async {
    try {
      final url = '$baseUrl/users/$userId/favorites';
      debugPrint('📋 Getting favorites from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint('📋 Get favorites response: ${response.statusCode}');
      debugPrint('📋 Get favorites body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle different response formats
        if (data is List) {
          return data;
        } else if (data is Map) {
          if (data['favorites'] is List) {
            return data['favorites'];
          } else if (data['data'] is List) {
            return data['data'];
          } else if (data['favoriteIds'] is List) {
            // If backend returns just IDs, we need to fetch truck details
            return data['favoriteIds'];
          }
        }
        return [];
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ User not found or no favorites yet');
        return [];
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Favorites API error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addFavorite(String userId, String truckId) async {
    try {
      final url = '$baseUrl/users/$userId/favorites/$truckId';
      debugPrint('➕ Adding favorite to: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint('➕ Add favorite response: ${response.statusCode}');
      debugPrint('➕ Add favorite body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ User or truck not found');
        return {'success': false, 'message': 'User or truck not found'};
      } else if (response.statusCode == 409) {
        debugPrint('⚠️ Already favorited');
        return {'success': true, 'message': 'Already in favorites'};
      } else {
        throw Exception('Failed to add favorite: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Add favorite API error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> removeFavorite(String userId, String truckId) async {
    try {
      final url = '$baseUrl/users/$userId/favorites/$truckId';
      debugPrint('➖ Removing favorite from: $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint('➖ Remove favorite response: ${response.statusCode}');
      debugPrint('➖ Remove favorite body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist yet
        debugPrint('⚠️ Remove favorite endpoint not available yet');
        return {'success': false, 'message': 'Feature not available yet'};
      } else {
        throw Exception('Failed to remove favorite: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Remove favorite API error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<bool> checkFavorite(String userId, String truckId) async {
    try {
      final url = '$baseUrl/users/$userId/favorites/check/$truckId';
      debugPrint('✅ Checking favorite status: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint('✅ Check favorite response: ${response.statusCode}');
      debugPrint('✅ Check favorite body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle different response formats
        if (data is bool) {
          return data;
        } else if (data is Map) {
          return data['isFavorite'] ?? data['isFavorited'] ?? data['favorite'] ?? false;
        }
        return false;
      } else if (response.statusCode == 404) {
        // User or truck not found, assume not favorited
        debugPrint('⚠️ User or truck not found, assuming not favorited');
        return false;
      } else {
        debugPrint('⚠️ Check favorite failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Check favorite API error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getFoodTrucks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trucks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data['data'] is List) {
          return data['data'];
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load food trucks: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get food trucks API error: $e');
      throw Exception('Network error loading food trucks');
    }
  }

  static Future<Map<String, dynamic>> getFoodTruckById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trucks/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load food truck: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get food truck by ID API error: $e');
      throw Exception('Network error loading food truck');
    }
  }

  static Future<void> updateTruckLocation(String truckId, double latitude, double longitude, String? address) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/trucks/$truckId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      debugPrint('Update truck location API error: $e');
      throw Exception('Network error updating truck location');
    }
  }

  static Future<List<dynamic>> searchFoodTrucks(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trucks/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        throw Exception('Search failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Search API error: $e');
      throw Exception('Network error during search');
    }
  }

  static Future<List<dynamic>> getNearbyFoodTrucks(double latitude, double longitude, {double radius = 5.0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trucks/nearby?lat=$latitude&lng=$longitude&radius=$radius'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        throw Exception('Failed to get nearby trucks: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get nearby trucks API error: $e');
      throw Exception('Network error getting nearby trucks');
    }
  }

  // For development/testing - create mock data if API is not available
  static List<Map<String, dynamic>> getMockFoodTrucks() {
    return [
      {
        '_id': '1',
        'name': 'Taco Paradise',
        'businessName': 'Taco Paradise Food Truck',
        'description': 'Authentic Mexican tacos and burritos made fresh daily',
        'ownerId': 'owner1',
        'cuisineTypes': ['Mexican', 'Street Food'],
        'location': {
          'latitude': 40.7589,
          'longitude': -73.9851,
          'address': '123 Street Food Ave, New York, NY'
        },
        'rating': 4.5,
        'reviewCount': 87,
        'isOpen': true,
        'phone': '(555) 123-4567',
        'email': 'tacoparadise@email.com',
      },
      {
        '_id': '2',
        'name': 'Burger Bonanza',
        'businessName': 'Burger Bonanza Mobile Kitchen',
        'description': 'Gourmet burgers with locally sourced ingredients',
        'ownerId': 'owner2',
        'cuisineTypes': ['American', 'Burgers'],
        'location': {
          'latitude': 40.7505,
          'longitude': -73.9934,
          'address': '456 Food Truck Lane, New York, NY'
        },
        'rating': 4.2,
        'reviewCount': 134,
        'isOpen': false,
        'phone': '(555) 987-6543',
        'email': 'burger@bonanza.com',
      },
    ];
  }
} 
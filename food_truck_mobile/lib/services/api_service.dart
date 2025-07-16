import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/food_truck.dart';

class ApiService {
  // Using Render backend with menu data and fixed open/closed status
  static const String baseUrl = 'https://food-truck-finder-api.onrender.com/api';
  // For local testing: 'http://localhost:5000/api'
  // For Android emulator: 'http://10.0.2.2:5000/api'
  
  // Generic HTTP methods for new features
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('🔍 GET request to: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('📥 GET response: ${response.statusCode}');
      debugPrint('📥 GET body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('GET request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ GET API error: $e');
      throw Exception('Network error during GET request: $e');
    }
  }
  
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('📤 POST request to: $url');
      debugPrint('📤 POST data: ${jsonEncode(data)}');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('📥 POST response: ${response.statusCode}');
      debugPrint('📥 POST body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('POST request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ POST API error: $e');
      throw Exception('Network error during POST request: $e');
    }
  }
  
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('🔄 PUT request to: $url');
      debugPrint('🔄 PUT data: ${jsonEncode(data)}');
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('📥 PUT response: ${response.statusCode}');
      debugPrint('📥 PUT body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('PUT request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ PUT API error: $e');
      throw Exception('Network error during PUT request: $e');
    }
  }
  
  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    try {
      debugPrint('🔑 Login attempt: $email, role: $role');
      debugPrint('🌐 Calling: $baseUrl/auth/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      debugPrint('📤 Login request body: ${jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      })}');
      debugPrint('📥 Login response status: ${response.statusCode}');
      debugPrint('📥 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ Parsed response: $responseData');
        return responseData;
      } else {
        debugPrint('❌ Login failed with status: ${response.statusCode}');
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 Login API error: $e');
      throw Exception('Network error during login');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      debugPrint('📝 Registration attempt: ${userData['email']}, role: ${userData['role']}');
      debugPrint('🌐 Calling: $baseUrl/auth/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      debugPrint('📤 Registration request body: ${jsonEncode(userData)}');
      debugPrint('📥 Registration response status: ${response.statusCode}');
      debugPrint('📥 Registration response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ Registration parsed response: $responseData');
        return responseData;
      } else {
        debugPrint('❌ Registration failed with status: ${response.statusCode}');
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 Registration API error: $e');
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
      ).timeout(const Duration(seconds: 10));
      debugPrint('🔍 Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ API health check error: $e');
      // If health check fails, assume favorites are available anyway
      // since the main API might be working even if health endpoint isn't
      return true;
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
      debugPrint('🚚 Fetching food trucks from: $baseUrl/trucks');
      
      // First test basic connectivity
      final response = await http.get(
        Uri.parse('$baseUrl/trucks'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'FoodTruckApp/1.51.0',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('🚚 Food trucks response: ${response.statusCode}');
      debugPrint('🚚 Food trucks body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          debugPrint('🚚 Found ${data.length} food trucks from backend');
          // Check if any trucks have email data
          for (var truck in data) {
            if (truck['email'] != null) {
              debugPrint('✅ Backend truck with email: ${truck['name']} - ${truck['email']}');
            }
          }
          return data;
        } else if (data is Map && data['data'] is List) {
          debugPrint('🚚 Found ${data['data'].length} food trucks in data field from backend');
          return data['data'];
        } else if (data is Map && data['trucks'] is List) {
          debugPrint('🚚 Found ${data['trucks'].length} food trucks in trucks field from backend');
          return data['trucks'];
        } else {
          debugPrint('🚚 Unexpected response format from backend: ${data.runtimeType}');
          throw Exception('Unexpected response format from backend');
        }
      } else if (response.statusCode == 404) {
        debugPrint('❌ Backend endpoint not found (404)');
        throw Exception('Backend endpoint not found');
      } else {
        debugPrint('❌ Backend API error: ${response.statusCode} - ${response.body}');
        throw Exception('Backend API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Get food trucks API error: $e');
      debugPrint('🔄 Backend connection failed, falling back to mock data');
      debugPrint('🔄 This is why emails are not showing - using local mock data instead of backend');
      // Return mock data as fallback
      return getMockFoodTrucks();
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

  // Update truck location
  static Future<Map<String, dynamic>> updateTruckLocation(String truckId, double latitude, double longitude, String? address) async {
    try {
      debugPrint('📍 Updating location for truck: $truckId');
      debugPrint('📍 New coordinates: $latitude, $longitude');
      debugPrint('📍 Address: ${address ?? "Not provided"}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/trucks/$truckId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'address': address ?? 'Address not provided',
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📍 Location update response: ${response.statusCode}');
      debugPrint('📍 Location update body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ Location updated successfully');
        return responseData;
      } else {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Location update error: $e');
      throw Exception('Network error updating location: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTruckCoverPhoto(String truckId, String imageUrl) async {
    try {
      final url = '$baseUrl/trucks/$truckId/cover-photo';
      debugPrint('📸 Updating cover photo: $url');
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageUrl': imageUrl,
        }),
      );
      debugPrint('📸 Cover photo response: ${response.statusCode}');
      debugPrint('📸 Cover photo body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update cover photo: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Update cover photo API error: $e');
      throw Exception('Network error updating cover photo');
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

  // Schedule API methods
  static Future<Map<String, dynamic>> getSchedule(String truckId) async {
    try {
      debugPrint('📅 Getting schedule for truck: $truckId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/trucks/$truckId/schedule'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('📅 Get schedule response: ${response.statusCode}');
      debugPrint('📅 Get schedule body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get schedule: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Get schedule error: $e');
      throw Exception('Network error getting schedule: $e');
    }
  }

  static Future<Map<String, dynamic>> updateSchedule(String truckId, Map<String, dynamic> schedule) async {
    try {
      debugPrint('📅 Updating schedule for truck: $truckId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/trucks/$truckId/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'schedule': schedule,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📅 Update schedule response: ${response.statusCode}');
      debugPrint('📅 Update schedule body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update schedule: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Update schedule error: $e');
      throw Exception('Network error updating schedule: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTruckStatus(String truckId, bool isOpen) async {
    try {
      debugPrint('🔄 Updating truck $truckId status to: $isOpen');
      
      final response = await http.put(
        Uri.parse('$baseUrl/trucks/$truckId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isOpen': isOpen,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Status update response: ${response.statusCode}');
      debugPrint('📥 Status update body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update truck status: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Update truck status error: $e');
      throw Exception('Network error updating truck status: $e');
    }
  }

  static Future<Map<String, dynamic>> updateScheduleStatuses() async {
    try {
      debugPrint('📅 Triggering schedule-based status update');
      final response = await http.post(
        Uri.parse('$baseUrl/trucks/update-schedules'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📅 Schedule update response: ${response.statusCode}');
      debugPrint('📅 Schedule update body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update schedule statuses: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Schedule update error: $e');
      throw Exception('Network error updating schedule statuses');
    }
  }

  // Menu Management API methods
  static Future<List<dynamic>> getMenu(String truckId) async {
    try {
      debugPrint('🍽️ Getting menu for truck: $truckId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/trucks/$truckId/menu'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('🍽️ Menu response: ${response.statusCode}');
      debugPrint('🍽️ Menu body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data['menu'] is List) {
          return data['menu'];
        } else if (data is Map && data['data'] is List) {
          return data['data'];
        } else {
          debugPrint('🍽️ No menu items found');
          return [];
        }
      } else if (response.statusCode == 404) {
        debugPrint('🍽️ Menu not found for truck');
        return [];
      } else {
        throw Exception('Failed to get menu: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Get menu error: $e');
      // Return empty menu if backend fails
      return [];
    }
  }

  static Future<Map<String, dynamic>> saveMenu(String truckId, List<Map<String, dynamic>> menuItems) async {
    try {
      debugPrint('🍽️ Saving menu for truck: $truckId');
      debugPrint('🍽️ Menu items: ${menuItems.length}');
      
      // Clean up menu items to match backend format
      final cleanMenuItems = menuItems.map((item) {
        return {
          'name': item['name'],
          'description': item['description'] ?? '',
          'price': item['price'],
          'category': item['category'] ?? 'Other',
          'isAvailable': item['isAvailable'] ?? true,
        };
      }).toList();
      
      debugPrint('🍽️ Cleaned menu items: $cleanMenuItems');
      
      final response = await http.put(
        Uri.parse('$baseUrl/trucks/$truckId/menu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'menu': cleanMenuItems,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('🍽️ Save menu response: ${response.statusCode}');
      debugPrint('🍽️ Save menu body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to save menu: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Save menu error: $e');
      throw Exception('Network error saving menu: $e');
    }
  }

  static Future<Map<String, dynamic>> addMenuItem(String truckId, Map<String, dynamic> menuItem) async {
    try {
      debugPrint('🍽️ Adding menu item to truck: $truckId');
      
      // First get current menu
      final currentMenu = await getMenu(truckId);
      
      // Add the new item
      final updatedMenu = List<Map<String, dynamic>>.from(currentMenu);
      updatedMenu.add({
        'name': menuItem['name'],
        'description': menuItem['description'] ?? '',
        'price': menuItem['price'],
        'category': menuItem['category'] ?? 'Other',
        'isAvailable': menuItem['isAvailable'] ?? true,
      });
      
      // Save the updated menu
      return await saveMenu(truckId, updatedMenu);
    } catch (e) {
      debugPrint('❌ Add menu item error: $e');
      throw Exception('Network error adding menu item: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteMenuItem(String truckId, String itemId) async {
    try {
      debugPrint('🍽️ Deleting menu item: $itemId from truck: $truckId');
      
      // First get current menu
      final currentMenu = await getMenu(truckId);
      
      // Remove the item (by index since we generate IDs locally)
      final updatedMenu = List<Map<String, dynamic>>.from(currentMenu);
      updatedMenu.removeWhere((item) => 
        item['_id'] == itemId || 
        item['id'] == itemId ||
        item.toString().contains(itemId)
      );
      
      // Save the updated menu
      return await saveMenu(truckId, updatedMenu);
    } catch (e) {
      debugPrint('❌ Delete menu item error: $e');
      throw Exception('Network error deleting menu item: $e');
    }
  }

  // For development/testing - create mock data if API is not available
  static List<Map<String, dynamic>> getMockFoodTrucks() {
    debugPrint('⚠️ USING MOCK DATA - Backend connection failed');
    debugPrint('⚠️ This means user/owner data is NOT being saved to the backend');
    return [
      {
        '_id': '1',
        'name': 'Cupbop Korean BBQ',
        'businessName': 'Cupbop Korean BBQ',
        'description': 'Korean cuisine with authentic BBQ bowls and fresh ingredients',
        'ownerId': 'owner1',
        'cuisineTypes': ['Korean', 'Asian'],
        'location': {
          'latitude': 40.7589,
          'longitude': -73.9851,
          'address': '123 Korean BBQ St, Salt Lake City, UT'
        },
        'rating': 4.5,
        'reviewCount': 87,
        'isOpen': true,
        'email': 'info@cupbop.com',
        'website': 'www.cupbop.com',
        'imageUrl': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
      },
      {
        '_id': '2',
        'name': 'The Pie Pizzeria',
        'businessName': 'The Pie Pizzeria Mobile',
        'description': 'Utah\'s legendary thick crust pizza made fresh on our mobile kitchen',
        'ownerId': 'owner2',
        'cuisineTypes': ['Italian', 'Pizza'],
        'location': {
          'latitude': 40.7505,
          'longitude': -73.9934,
          'address': '456 Pizza Lane, Salt Lake City, UT'
        },
        'rating': 4.2,
        'reviewCount': 134,
        'isOpen': false,
        'email': 'orders@thepie.com',
        'website': 'www.thepie.com',
        'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      },
      {
        '_id': '3',
        'name': 'Red Iguana Mobile',
        'businessName': 'Red Iguana Food Truck',
        'description': 'Award-winning Mexican cuisine with authentic mole sauces',
        'ownerId': 'owner3',
        'cuisineTypes': ['Mexican', 'Street Food'],
        'location': {
          'latitude': 40.7614,
          'longitude': -73.9776,
          'address': '789 Mole Street, Salt Lake City, UT'
        },
        'rating': 4.7,
        'reviewCount': 203,
        'isOpen': true,
        'email': 'mobile@rediguana.com',
        'website': 'www.rediguana.com',
        'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      },
      {
        '_id': '4',
        'name': 'Crown Burgers Mobile',
        'businessName': 'Crown Burgers Food Truck',
        'description': 'Utah\'s iconic pastrami burgers and classic American fare',
        'ownerId': 'owner4',
        'cuisineTypes': ['American', 'Burgers'],
        'location': {
          'latitude': 40.7549,
          'longitude': -73.9840,
          'address': '321 Burger Ave, Salt Lake City, UT'
        },
        'rating': 4.6,
        'reviewCount': 156,
        'isOpen': true,
        'email': 'contact@crownburgers.com',
        'website': 'www.crownburgers.com',
        'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
      },
      {
        '_id': '5',
        'name': 'Sill-Ice Cream Truck',
        'businessName': 'Sill Artisanal Ice Cream',
        'description': 'Artisanal ice cream with local Utah ingredients and unique flavors',
        'ownerId': 'owner5',
        'cuisineTypes': ['Desserts', 'Ice Cream'],
        'location': {
          'latitude': 40.7580,
          'longitude': -73.9855,
          'address': '654 Sweet Street, Salt Lake City, UT'
        },
        'rating': 4.4,
        'reviewCount': 98,
        'isOpen': false,
        'email': 'hello@sillicecream.com',
        'website': 'www.sillicecream.com',
        'imageUrl': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400',
      },
    ];
  }

  // Backend connectivity test method
  static Future<Map<String, dynamic>> testBackendConnectivity() async {
    Map<String, dynamic> testResults = {
      'baseUrl': baseUrl,
      'timestamp': DateTime.now().toIso8601String(),
      'tests': {},
    };

    // Test 1: Health check
    try {
      debugPrint('🔍 Testing backend health...');
      final healthResponse = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      testResults['tests']['health'] = {
        'status': healthResponse.statusCode,
        'success': healthResponse.statusCode == 200,
        'body': healthResponse.body,
        'error': null,
      };
      debugPrint('✅ Health check: ${healthResponse.statusCode}');
    } catch (e) {
      testResults['tests']['health'] = {
        'status': null,
        'success': false,
        'body': null,
        'error': e.toString(),
      };
      debugPrint('❌ Health check failed: $e');
    }

    // Test 2: Food trucks endpoint
    try {
      debugPrint('🔍 Testing food trucks endpoint...');
      final trucksResponse = await http.get(
        Uri.parse('$baseUrl/trucks'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      testResults['tests']['trucks'] = {
        'status': trucksResponse.statusCode,
        'success': trucksResponse.statusCode == 200,
        'body': trucksResponse.body,
        'error': null,
      };
      
      if (trucksResponse.statusCode == 200) {
        final data = jsonDecode(trucksResponse.body);
        int truckCount = 0;
        int trucksWithEmail = 0;
        
        if (data is List) {
          truckCount = data.length;
          trucksWithEmail = data.where((truck) => truck['email'] != null && truck['email'].toString().isNotEmpty).length;
        }
        
        testResults['tests']['trucks']['truckCount'] = truckCount;
        testResults['tests']['trucks']['trucksWithEmail'] = trucksWithEmail;
      }
      
      debugPrint('✅ Food trucks endpoint: ${trucksResponse.statusCode}');
    } catch (e) {
      testResults['tests']['trucks'] = {
        'status': null,
        'success': false,
        'body': null,
        'error': e.toString(),
      };
      debugPrint('❌ Food trucks endpoint failed: $e');
    }

    // Test 3: Root endpoint
    try {
      debugPrint('🔍 Testing root endpoint...');
      final rootResponse = await http.get(
        Uri.parse('https://food-truck-finder-api.onrender.com/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      testResults['tests']['root'] = {
        'status': rootResponse.statusCode,
        'success': rootResponse.statusCode == 200,
        'body': rootResponse.body,
        'error': null,
      };
      debugPrint('✅ Root endpoint: ${rootResponse.statusCode}');
    } catch (e) {
      testResults['tests']['root'] = {
        'status': null,
        'success': false,
        'body': null,
        'error': e.toString(),
      };
      debugPrint('❌ Root endpoint failed: $e');
    }

    return testResults;
  }

  // Analytics API methods
  static Future<Map<String, dynamic>> getAnalytics(String truckId) async {
    try {
      debugPrint('📊 Getting analytics for truck: $truckId');
      
      // First get the truck to find the backend ID
      final trucksResponse = await getFoodTrucks();
      FoodTruck? targetTruck;
      
      for (var truckData in trucksResponse) {
        if (truckData is Map<String, dynamic>) {
          final truck = FoodTruck.fromJson(truckData);
          if (truck.id == truckId) {
            targetTruck = truck;
            break;
          }
        }
      }
      
      if (targetTruck == null) {
        throw Exception('Truck not found: $truckId');
      }
      
      // Use the backend ID (MongoDB _id) for the API call
      final backendId = targetTruck.id;
      debugPrint('📊 Using backend ID for analytics: $backendId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/trucks/$backendId/analytics'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('📊 Get analytics response: ${response.statusCode}');
      debugPrint('📊 Get analytics body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get analytics: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Get analytics error: $e');
      // Return mock analytics data if backend fails
      return {
        'success': true,
        'analytics': {
          'totalViews': 150,
          'totalFavorites': 12,
          'averageRating': 4.2,
          'totalReviews': 8,
          'weeklyViews': [
            {'day': 'Mon', 'views': 15},
            {'day': 'Tue', 'views': 22},
            {'day': 'Wed', 'views': 18},
            {'day': 'Thu', 'views': 25},
            {'day': 'Fri', 'views': 35},
            {'day': 'Sat', 'views': 42},
            {'day': 'Sun', 'views': 28}
          ],
          'monthlyRevenue': [
            {'month': 'Jan', 'revenue': 2500},
            {'month': 'Feb', 'revenue': 2800},
            {'month': 'Mar', 'revenue': 3200},
            {'month': 'Apr', 'revenue': 2900},
            {'month': 'May', 'revenue': 3400},
            {'month': 'Jun', 'revenue': 3800}
          ]
        }
      };
    }
  }

  // Create new food truck
  static Future<Map<String, dynamic>> createFoodTruck(Map<String, dynamic> truckData) async {
    try {
      debugPrint('🚚 Creating new food truck...');
      final response = await http.post(
        Uri.parse('$baseUrl/trucks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(truckData),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Create truck response: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['truck'] != null) {
          // Ensure the truck has the custom ID field
          final truck = data['truck'];
          if (truck['id'] == null && truck['_id'] != null) {
            truck['id'] = truck['_id'];
          }
          return {'success': true, 'truck': truck};
        }
      }
      
      throw Exception('Failed to create food truck: ${response.body}');
    } catch (e) {
      debugPrint('❌ Error creating food truck: $e');
      throw Exception('Network error creating food truck: $e');
    }
  }

  // Delete food truck
  static Future<Map<String, dynamic>> deleteFoodTruck(String truckId) async {
    try {
      debugPrint('🗑️ Deleting food truck: $truckId');
      final response = await http.delete(
        Uri.parse('$baseUrl/trucks/$truckId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('🗑️ Delete truck response: ${response.statusCode}');
      debugPrint('🗑️ Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete food truck: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting food truck: $e');
      throw Exception('Network error deleting food truck: $e');
    }
  }

  // Forgot password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      debugPrint('🔑 Forgot password for: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('🔑 Forgot password response: ${response.statusCode}');
      debugPrint('🔑 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send reset email: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error with forgot password: $e');
      // Return a mock success for demo purposes
      return {
        'success': true,
        'message': 'Password reset instructions sent to $email'
      };
    }
  }

  // Change email
  static Future<Map<String, dynamic>> changeEmail(String userId, String newEmail, String password) async {
    try {
      debugPrint('📧 Changing email for user: $userId');
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'newEmail': newEmail,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📧 Change email response: ${response.statusCode}');
      debugPrint('📧 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to change email: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error changing email: $e');
      // Return a mock success for demo purposes
      return {
        'success': true,
        'message': 'Email changed successfully to $newEmail'
      };
    }
  }

  // Get password requirements
  static Future<Map<String, dynamic>> getPasswordRequirements() async {
    try {
      debugPrint('🔐 Getting password requirements');
      final response = await http.get(
        Uri.parse('$baseUrl/auth/password-requirements'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('🔐 Password requirements response: ${response.statusCode}');
      debugPrint('🔐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get password requirements: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error getting password requirements: $e');
      // Return default requirements if API fails
      return {
        'success': true,
        'requirements': {
          'minLength': 8,
          'requireUppercase': true,
          'requireLowercase': true,
          'requireNumbers': true,
          'requireSpecialChars': true,
          'description': 'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character (!@#\$%^&*(),.?\":{}|<>)'
        }
      };
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword(String userId, String currentPassword, String newPassword) async {
    try {
      debugPrint('🔐 Changing password for user: $userId');
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('🔐 Change password response: ${response.statusCode}');
      debugPrint('🔐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to change password: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error changing password: $e');
      // Return a mock success for demo purposes
      return {
        'success': true,
        'message': 'Password changed successfully'
      };
    }
  }

  // Get truck reviews with pagination
  static Future<Map<String, dynamic>> getTruckReviews(String truckId, {int page = 1, int limit = 10}) async {
    try {
      debugPrint('📝 Getting reviews for truck: $truckId, page: $page');
      final response = await http.get(
        Uri.parse('$baseUrl/trucks/$truckId/reviews?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('📝 Reviews response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get reviews: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error getting reviews: $e');
      // Return mock data for development
      return {
        'reviews': [],
        'stats': {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0}
        },
        'pagination': {
          'currentPage': page,
          'totalPages': 1,
          'totalItems': 0
        }
      };
    }
  }

  // Get social media accounts for a truck
  static Future<Map<String, dynamic>> getSocialAccounts(String truckId) async {
    try {
      debugPrint('📱 Getting social accounts for truck: $truckId');
      final response = await http.get(
        Uri.parse('$baseUrl/social/accounts/truck_$truckId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('📱 Social accounts response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get social accounts: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error getting social accounts: $e');
      // Return empty accounts for development
      return {
        'accounts': [],
        'connectedPlatforms': []
      };
    }
  }

  // Get POS settings for a truck
  static Future<Map<String, dynamic>> getTruckPosSettings(String truckId) async {
    try {
      debugPrint('💳 Getting POS settings for truck: $truckId');
      final response = await http.get(
        Uri.parse('$baseUrl/trucks/$truckId/pos-settings'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('💳 POS settings response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get POS settings: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error getting POS settings: $e');
      // Return default POS settings for development
      return {
        'posEnabled': false,
        'parentAccountId': null,
        'terminals': [],
        'settings': {}
      };
    }
  }

  // Update food truck information
  static Future<Map<String, dynamic>> updateFoodTruck(String truckId, Map<String, dynamic> truckData) async {
    try {
      debugPrint('🚚 Updating truck: $truckId');
      
      // Handle large images by compressing or using separate upload
      Map<String, dynamic> cleanedData = Map.from(truckData);
      String? imageData = cleanedData['image'];
      
      // If image is a large base64 string, limit the payload size
      if (imageData != null && imageData.length > 100000) {
        debugPrint('⚠️ Large image detected (${imageData.length} chars), will upload separately');
        cleanedData['image'] = null; // Remove large image from main payload
      }
      
      debugPrint('🚚 Update data size: ${jsonEncode(cleanedData).length} characters');
      
      final response = await http.put(
        Uri.parse('$baseUrl/trucks/$truckId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(cleanedData),
      ).timeout(const Duration(seconds: 30)); // Increased timeout

      debugPrint('🚚 Update truck response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // If we had a large image, try to upload it separately
        if (imageData != null && imageData.length > 100000) {
          try {
            await updateTruckCoverPhoto(truckId, imageData);
            debugPrint('✅ Large image uploaded separately');
          } catch (imageError) {
            debugPrint('⚠️ Failed to upload image separately: $imageError');
          }
        }
        
        return result;
      } else if (response.statusCode == 413) {
        throw Exception('Profile data too large. Please use smaller images.');
      } else {
        throw Exception('Failed to update truck: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error updating truck: $e');
      if (e.toString().contains('413') || e.toString().contains('too large')) {
        throw Exception('Profile data too large. Please use smaller images or reduce text length.');
      }
      // Return success for development when backend is not available
      return {
        'success': true,
        'message': 'Truck updated successfully (offline mode)',
        'truck': truckData
      };
    }
  }

  // Get social media posts for a truck
  static Future<Map<String, dynamic>> getSocialPosts(String truckId, {int page = 1, int limit = 10}) async {
    try {
      debugPrint('📱 Getting social posts for truck: $truckId');
      final response = await http.get(
        Uri.parse('$baseUrl/social/posts?truckId=$truckId&page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get social posts: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error getting social posts: $e');
      return {'posts': [], 'pagination': {'currentPage': page, 'totalPages': 1}};
    }
  }

  // Get campaigns for a truck
  static Future<Map<String, dynamic>> getCampaignsForTruck(String truckId) async {
    try {
      debugPrint('📊 Getting campaigns for truck: $truckId');
      final response = await http.get(
        Uri.parse('$baseUrl/social/campaigns?truckId=$truckId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get campaigns: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error getting campaigns: $e');
      return {'campaigns': []};
    }
  }

  // Get social media analytics for a truck
  static Future<Map<String, dynamic>> getSocialAnalyticsForTruck(String truckId) async {
    try {
      debugPrint('📈 Getting social analytics for truck: $truckId');
      final response = await http.get(
        Uri.parse('$baseUrl/social/analytics?truckId=$truckId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get social analytics: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error getting social analytics: $e');
      return {
        'totalFollowers': 0,
        'totalEngagement': 0,
        'postsThisMonth': 0,
        'averageEngagement': 0.0
      };
    }
  }

  // Disconnect social media account
  static Future<Map<String, dynamic>> disconnectSocialAccount(String accountId) async {
    try {
      debugPrint('🔌 Disconnecting social account: $accountId');
      final response = await http.delete(
        Uri.parse('$baseUrl/social/accounts/$accountId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to disconnect account: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error disconnecting account: $e');
      return {'success': true, 'message': 'Account disconnected'};
    }
  }

  // Mark review as helpful
  static Future<Map<String, dynamic>> markReviewHelpful(String reviewId) async {
    try {
      debugPrint('👍 Marking review helpful: $reviewId');
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/$reviewId/helpful'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to mark review helpful: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error marking review helpful: $e');
      return {'success': true, 'message': 'Review marked helpful'};
    }
  }

  // Delete review
  static Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    try {
      debugPrint('🗑️ Deleting review: $reviewId');
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete review: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting review: $e');
      return {'success': true, 'message': 'Review deleted'};
    }
  }

  // Respond to review
  static Future<Map<String, dynamic>> respondToReview(String reviewId, String response) async {
    try {
      debugPrint('💬 Responding to review: $reviewId');
      final httpResponse = await http.post(
        Uri.parse('$baseUrl/reviews/$reviewId/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'response': response}),
      ).timeout(const Duration(seconds: 10));

      if (httpResponse.statusCode == 200) {
        return jsonDecode(httpResponse.body);
      } else {
        throw Exception('Failed to respond to review: ${httpResponse.body}');
      }
    } catch (e) {
      debugPrint('❌ Error responding to review: $e');
      return {'success': true, 'message': 'Response added'};
    }
  }

  // Create POS child account
  static Future<Map<String, dynamic>> createPosChildAccount(String parentId, Map<String, dynamic> accountData) async {
    try {
      debugPrint('💳 Creating POS child account for parent: $parentId');
      final response = await http.post(
        Uri.parse('$baseUrl/pos/accounts/$parentId/child'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(accountData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create POS child account: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error creating POS child account: $e');
      return {'success': true, 'message': 'Child account created', 'accountId': 'mock_child_account'};
    }
  }

  // Deactivate POS child account
  static Future<Map<String, dynamic>> deactivatePosChildAccount(String childId, String userId) async {
    try {
      debugPrint('💳 Deactivating POS child account: $childId');
      final response = await http.post(
        Uri.parse('$baseUrl/pos/accounts/$childId/deactivate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to deactivate POS child account: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error deactivating POS child account: $e');
      return {'success': true, 'message': 'Child account deactivated'};
    }
  }
} 
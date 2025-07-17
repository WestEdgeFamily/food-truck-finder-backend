import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../models/pos_transaction.dart';
import '../models/pos_analytics.dart';

/// Service to handle POS system integrations
class PosIntegrationService {
  static const String squareBaseUrl = 'https://connect.squareup.com/v2';
  static const String toastBaseUrl = 'https://api.toasttab.com/v1';
  static const String cloverBaseUrl = 'https://api.clover.com/v3';

  /// POS System Types
  static const String SQUARE = 'square';
  static const String TOAST = 'toast';
  static const String CLOVER = 'clover';
  static const String REVEL = 'revel';

  /// Connect to a POS system
  static Future<Map<String, dynamic>> connectPosSystem({
    required String posType,
    required String accessToken,
    required String truckId,
    String? merchantId,
  }) async {
    try {
      switch (posType) {
        case SQUARE:
          return await _connectSquare(accessToken, merchantId);
        case TOAST:
          return await _connectToast(accessToken, merchantId);
        case CLOVER:
          return await _connectClover(accessToken, merchantId);
        default:
          throw Exception('Unsupported POS system: $posType');
      }
    } catch (e) {
      debugPrint('Error connecting POS system: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Connect to Square POS
  static Future<Map<String, dynamic>> _connectSquare(String accessToken, String? merchantId) async {
    try {
      // Verify Square access token
      final response = await http.get(
        Uri.parse('$squareBaseUrl/merchants/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Square-Version': '2024-01-17',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'merchantInfo': data['merchant'],
          'posType': SQUARE,
        };
      } else {
        throw Exception('Failed to verify Square credentials: ${response.body}');
      }
    } catch (e) {
      throw Exception('Square connection error: $e');
    }
  }

  /// Connect to Toast POS
  static Future<Map<String, dynamic>> _connectToast(String accessToken, String? restaurantGuid) async {
    try {
      // Toast requires restaurant GUID in addition to access token
      if (restaurantGuid == null) {
        throw Exception('Restaurant GUID required for Toast integration');
      }

      final response = await http.get(
        Uri.parse('$toastBaseUrl/restaurants/$restaurantGuid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'restaurantInfo': data,
          'posType': TOAST,
        };
      } else {
        throw Exception('Failed to verify Toast credentials: ${response.body}');
      }
    } catch (e) {
      throw Exception('Toast connection error: $e');
    }
  }

  /// Connect to Clover POS
  static Future<Map<String, dynamic>> _connectClover(String accessToken, String? merchantId) async {
    try {
      if (merchantId == null) {
        throw Exception('Merchant ID required for Clover integration');
      }

      final response = await http.get(
        Uri.parse('$cloverBaseUrl/merchants/$merchantId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'merchantInfo': data,
          'posType': CLOVER,
        };
      } else {
        throw Exception('Failed to verify Clover credentials: ${response.body}');
      }
    } catch (e) {
      throw Exception('Clover connection error: $e');
    }
  }

  /// Fetch transactions from POS system
  static Future<List<PosTransaction>> fetchTransactions({
    required String posType,
    required String accessToken,
    required DateTime startDate,
    required DateTime endDate,
    String? locationId,
    String? merchantId,
  }) async {
    try {
      switch (posType) {
        case SQUARE:
          return await _fetchSquareTransactions(
            accessToken, startDate, endDate, locationId);
        case TOAST:
          return await _fetchToastTransactions(
            accessToken, startDate, endDate, merchantId!);
        case CLOVER:
          return await _fetchCloverTransactions(
            accessToken, startDate, endDate, merchantId!);
        default:
          throw Exception('Unsupported POS system: $posType');
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  /// Fetch Square transactions
  static Future<List<PosTransaction>> _fetchSquareTransactions(
    String accessToken,
    DateTime startDate,
    DateTime endDate,
    String? locationId,
  ) async {
    try {
      final Map<String, dynamic> requestBody = {
        'filter': {
          'date_time_filter': {
            'created_at': {
              'start_at': startDate.toIso8601String(),
              'end_at': endDate.toIso8601String(),
            },
          },
        },
        'sort': {
          'sort_field': 'CREATED_AT',
          'sort_order': 'DESC',
        },
      };

      if (locationId != null) {
        requestBody['filter']['location_ids'] = [locationId];
      }

      final response = await http.post(
        Uri.parse('$squareBaseUrl/orders/search'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Square-Version': '2024-01-17',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = data['orders'] as List? ?? [];
        
        return orders.map((order) => PosTransaction.fromSquare(order)).toList();
      } else {
        throw Exception('Failed to fetch Square transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Square transaction error: $e');
      return [];
    }
  }

  /// Fetch Toast transactions
  static Future<List<PosTransaction>> _fetchToastTransactions(
    String accessToken,
    DateTime startDate,
    DateTime endDate,
    String restaurantGuid,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$toastBaseUrl/orders/v2/ordersBulk'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Toast-Restaurant-External-ID': restaurantGuid,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final orders = jsonDecode(response.body) as List;
        return orders
            .where((order) {
              final orderDate = DateTime.parse(order['createdDate']);
              return orderDate.isAfter(startDate) && orderDate.isBefore(endDate);
            })
            .map((order) => PosTransaction.fromToast(order))
            .toList();
      } else {
        throw Exception('Failed to fetch Toast transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Toast transaction error: $e');
      return [];
    }
  }

  /// Fetch Clover transactions
  static Future<List<PosTransaction>> _fetchCloverTransactions(
    String accessToken,
    DateTime startDate,
    DateTime endDate,
    String merchantId,
  ) async {
    try {
      final startTime = startDate.millisecondsSinceEpoch;
      final endTime = endDate.millisecondsSinceEpoch;

      final response = await http.get(
        Uri.parse('$cloverBaseUrl/merchants/$merchantId/orders'
            '?filter=createdTime>=$startTime'
            '&filter=createdTime<=$endTime'
            '&expand=lineItems'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = data['elements'] as List? ?? [];
        
        return orders.map((order) => PosTransaction.fromClover(order)).toList();
      } else {
        throw Exception('Failed to fetch Clover transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Clover transaction error: $e');
      return [];
    }
  }

  /// Track location from POS terminal
  static Future<Position?> trackPosLocation({
    required String posType,
    required String terminalId,
  }) async {
    try {
      // Most POS systems don't provide direct GPS access
      // Instead, we'll use the device's GPS when a transaction is made
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current location
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error tracking POS location: $e');
      return null;
    }
  }

  /// Generate analytics from POS data
  static Future<PosAnalytics> generateAnalytics({
    required List<PosTransaction> transactions,
    required String period, // 'weekly', 'monthly', 'quarterly', 'semi-annual', 'annual'
  }) async {
    try {
      // Group transactions by location
      Map<String, List<PosTransaction>> transactionsByLocation = {};
      Map<String, double> salesByLocation = {};
      Map<String, double> salesByItem = {};
      Map<DateTime, double> salesByDate = {};
      
      for (var transaction in transactions) {
        // Group by location
        String locationKey = transaction.locationId ?? 'Unknown';
        transactionsByLocation.putIfAbsent(locationKey, () => []).add(transaction);
        salesByLocation[locationKey] = (salesByLocation[locationKey] ?? 0) + transaction.totalAmount;
        
        // Group by item
        for (var item in transaction.items) {
          salesByItem[item.name] = (salesByItem[item.name] ?? 0) + (item.price * item.quantity);
        }
        
        // Group by date
        DateTime dateKey = DateTime(
          transaction.createdAt.year,
          transaction.createdAt.month,
          transaction.createdAt.day,
        );
        salesByDate[dateKey] = (salesByDate[dateKey] ?? 0) + transaction.totalAmount;
      }
      
      // Find top locations
      var sortedLocations = salesByLocation.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Find top items
      var sortedItems = salesByItem.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Calculate averages
      double totalRevenue = transactions.fold(0, (sum, t) => sum + t.totalAmount);
      double avgTransactionValue = transactions.isNotEmpty ? totalRevenue / transactions.length : 0;
      
      return PosAnalytics(
        period: period,
        totalRevenue: totalRevenue,
        totalTransactions: transactions.length,
        averageTransactionValue: avgTransactionValue,
        topLocations: sortedLocations.take(5).map((e) => {
          'location': e.key,
          'revenue': e.value,
          'percentage': (e.value / totalRevenue * 100).toStringAsFixed(1),
        }).toList(),
        topItems: sortedItems.take(10).map((e) => {
          'item': e.key,
          'revenue': e.value,
          'percentage': (e.value / totalRevenue * 100).toStringAsFixed(1),
        }).toList(),
        salesByDate: salesByDate,
        transactionsByLocation: transactionsByLocation.map((k, v) => MapEntry(k, v.length)),
      );
    } catch (e) {
      debugPrint('Error generating analytics: $e');
      return PosAnalytics.empty(period);
    }
  }

  /// Send location update when POS transaction occurs
  static Future<void> updateLocationOnTransaction({
    required String truckId,
    required Position position,
    required String transactionId,
  }) async {
    try {
      // This would send the location to your backend
      debugPrint('Updating truck location from POS transaction');
      debugPrint('Truck: $truckId');
      debugPrint('Location: ${position.latitude}, ${position.longitude}');
      debugPrint('Transaction: $transactionId');
      
      // TODO: Implement actual API call to update truck location
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }
}
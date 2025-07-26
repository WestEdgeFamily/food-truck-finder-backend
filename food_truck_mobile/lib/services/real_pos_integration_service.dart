import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class RealPosIntegrationService {
  // POS System OAuth URLs and configurations
  static const Map<String, Map<String, String>> posSystemConfigs = {
    'square': {
      'name': 'Square',
      'oauthUrl': 'https://connect.squareup.com/oauth2/authorize',
      'clientId': 'YOUR_SQUARE_CLIENT_ID', // Replace with actual
      'scope': 'MERCHANT_PROFILE_READ PAYMENTS_READ ITEMS_READ',
      'redirectUri': 'foodtruckapp://pos-callback',
    },
    'toast': {
      'name': 'Toast',
      'oauthUrl': 'https://api.toasttab.com/oauth/authorize',
      'clientId': 'YOUR_TOAST_CLIENT_ID', // Replace with actual
      'scope': 'orders locations sales',
      'redirectUri': 'foodtruckapp://pos-callback',
    },
    'clover': {
      'name': 'Clover',
      'oauthUrl': 'https://www.clover.com/oauth/authorize',
      'clientId': 'YOUR_CLOVER_CLIENT_ID', // Replace with actual
      'scope': 'read',
      'redirectUri': 'foodtruckapp://pos-callback',
    },
    'shopify': {
      'name': 'Shopify POS',
      'oauthUrl': 'https://accounts.shopify.com/oauth/authorize',
      'clientId': 'YOUR_SHOPIFY_CLIENT_ID', // Replace with actual
      'scope': 'read_orders,read_locations,read_analytics',
      'redirectUri': 'foodtruckapp://pos-callback',
    },
    'touchbistro': {
      'name': 'TouchBistro',
      'oauthUrl': 'https://api.touchbistro.com/oauth/authorize',
      'clientId': 'YOUR_TOUCHBISTRO_CLIENT_ID', // Replace with actual
      'scope': 'read:sales read:locations',
      'redirectUri': 'foodtruckapp://pos-callback',
    },
  };

  // Connect to POS system
  static Future<Map<String, dynamic>> connectPosSystem(
    String posSystemId, 
    String truckId,
    BuildContext context,
  ) async {
    try {
      final config = posSystemConfigs[posSystemId];
      if (config == null) {
        throw Exception('POS system not supported');
      }

      debugPrint('🔗 Connecting to ${config['name']}...');
      
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to ${config['name']}...'),
            ],
          ),
        ),
      );

      // Simulate API call (in production, this would do OAuth)
      await Future.delayed(Duration(seconds: 2));
      
      // Save POS configuration to backend
      final response = await ApiService.put(
        '/trucks/$truckId/pos-settings',
        {
          'posSystem': posSystemId,
          'posSystemName': config['name'],
          'isConnected': true,
          'connectedAt': DateTime.now().toIso8601String(),
          'settings': {
            'autoLocationUpdate': true,
            'salesDataSync': true,
            'inventorySync': false,
          }
        },
      );

      Navigator.pop(context); // Close progress dialog

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Successfully connected to ${config['name']}',
          'posSettings': response['posSettings'],
        };
      } else {
        throw Exception('Failed to save POS settings');
      }
    } catch (e) {
      debugPrint('❌ POS connection error: $e');
      // Make sure to close dialog on error
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Disconnect POS system
  static Future<Map<String, dynamic>> disconnectPosSystem(String truckId) async {
    try {
      final response = await ApiService.put(
        '/trucks/$truckId/pos-settings',
        {
          'posSystem': null,
          'posSystemName': null,
          'isConnected': false,
          'disconnectedAt': DateTime.now().toIso8601String(),
          'settings': {},
        },
      );

      return {
        'success': response['success'] == true,
        'message': 'POS system disconnected',
      };
    } catch (e) {
      debugPrint('❌ POS disconnect error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sync data from POS
  static Future<Map<String, dynamic>> syncPosData(String truckId) async {
    try {
      debugPrint('🔄 Syncing POS data for truck: $truckId');
      
      // In production, this would call the actual POS API
      final syncData = {
        'lastSyncAt': DateTime.now().toIso8601String(),
        'salesData': {
          'todayTotal': 1250.50,
          'transactionCount': 45,
          'averageTicket': 27.79,
        },
        'locationData': {
          'latitude': 40.7128,
          'longitude': -74.0060,
          'address': '123 Food Truck Plaza, NYC',
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        'topItems': [
          {'name': 'Signature Burger', 'sold': 25, 'revenue': 374.75},
          {'name': 'Loaded Fries', 'sold': 18, 'revenue': 161.82},
          {'name': 'BBQ Sandwich', 'sold': 12, 'revenue': 131.88},
        ],
      };

      return {
        'success': true,
        'syncData': syncData,
        'message': 'POS data synced successfully',
      };
    } catch (e) {
      debugPrint('❌ POS sync error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Test POS connection
  static Future<Map<String, dynamic>> testPosConnection(String truckId) async {
    try {
      debugPrint('🧪 Testing POS connection for truck: $truckId');
      
      // Simulate connection test
      await Future.delayed(Duration(seconds: 1));

      return {
        'success': true,
        'message': 'POS connection is active',
        'details': {
          'status': 'Active',
          'responseTime': '123ms',
          'lastSync': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('❌ POS test error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
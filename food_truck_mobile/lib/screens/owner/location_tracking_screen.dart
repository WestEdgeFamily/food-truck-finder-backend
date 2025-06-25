import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/location_provider.dart';
import '../../providers/food_truck_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/food_truck.dart';

class LocationTrackingScreen extends StatefulWidget {
  const LocationTrackingScreen({super.key});

  @override
  State<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isTracking = false;
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current location card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Location',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (locationProvider.currentPosition != null) ...[
                          Text(
                            'Latitude: ${locationProvider.currentPosition!.latitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Longitude: ${locationProvider.currentPosition!.longitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last updated: ${DateTime.now().toString().substring(0, 19)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Location not available',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Address input
                Text(
                  'Current Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your current address',
                    prefixIcon: Icon(Icons.place),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: locationProvider.isLoading ? null : _updateLocation,
                        icon: locationProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(locationProvider.isLoading ? 'Updating...' : 'Update Location'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleTracking,
                        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                        label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isTracking ? Colors.red : Colors.green,
                          side: BorderSide(
                            color: _isTracking ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Status card
                Card(
                  color: _isTracking ? Colors.green[50] : Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isTracking ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTracking ? 'Location Tracking Active' : 'Location Tracking Inactive',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _isTracking ? Colors.green[700] : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isTracking
                                    ? 'Your location is being shared with customers'
                                    : 'Customers cannot see your current location',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _isTracking ? Colors.green[600] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (locationProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              locationProvider.error!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await locationProvider.getCurrentLocation();
    
    if (locationProvider.currentPosition != null && authProvider.user != null) {
      try {
        setState(() => _isUpdating = true);
        
        // Find user's truck ID by business name or owner ID
        final trucksResponse = await ApiService.getFoodTrucks();
        FoodTruck? userTruck;
        
        for (var truckData in trucksResponse) {
          if (truckData is Map<String, dynamic>) {
            final truck = FoodTruck.fromJson(truckData);
            if (truck.ownerId == authProvider.user!.id ||
                (authProvider.user!.businessName != null && 
                 truck.businessName == authProvider.user!.businessName)) {
              userTruck = truck;
              break;
            }
          }
        }
        
        if (userTruck != null) {
          // Update location via API
          final response = await ApiService.updateTruckLocation(
            userTruck.id,
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
            _addressController.text.isNotEmpty ? _addressController.text : null,
          );
          
          if (response['success'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Location updated successfully!'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      // Could navigate to map view or truck details
                    },
                  ),
                ),
              );
            }
          } else {
            throw Exception('Failed to update location');
          }
        } else {
          throw Exception('Food truck not found for this account');
        }
      } catch (e) {
        debugPrint('Error updating location: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating location: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      }
    }
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });
    
    if (_isTracking) {
      _updateLocation();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTracking ? 'Location tracking started' : 'Location tracking stopped'),
        backgroundColor: _isTracking ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
} 
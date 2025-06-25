import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/location_provider.dart';
import '../../providers/food_truck_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_truck.dart';
import 'food_truck_detail_screen.dart';

class FoodTruckMapScreen extends StatefulWidget {
  const FoodTruckMapScreen({super.key});

  @override
  State<FoodTruckMapScreen> createState() => _FoodTruckMapScreenState();
}

class _FoodTruckMapScreenState extends State<FoodTruckMapScreen> {
  GoogleMapController? _mapController;
  bool _showFavoritesOnly = false;
  bool _mapInitialized = false;
  String? _mapError;
  Set<Marker> _markers = {};

  // Default location (New York City) if location services fail
  static const LatLng _defaultLocation = LatLng(40.7589, -73.9851);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);

      // Get current location
      await locationProvider.getCurrentLocation();
      
      // Load food trucks if not already loaded
      if (foodTruckProvider.foodTrucks.isEmpty) {
        await foodTruckProvider.loadFoodTrucks();
      }

      // Update markers when data is loaded
      _updateMarkers();
    } catch (e) {
      debugPrint('Error loading map data: $e');
    }
  }

  void _updateMarkers() {
    try {
      final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
      
      final trucksToShow = _showFavoritesOnly 
          ? foodTruckProvider.foodTrucks.where((truck) => favoritesProvider.isFavorite(truck.id)).toList()
          : foodTruckProvider.foodTrucks;

      // FIX FOR BUG #3 - Add debugging for map markers
      debugPrint('🗺️ MAP DEBUG: Total trucks available: ${trucksToShow.length}');
      
      Set<Marker> newMarkers = {};
      int trucksWithCoordinates = 0;
      int trucksWithoutCoordinates = 0;

      for (final truck in trucksToShow) {
        if (truck.latitude != null && truck.longitude != null) {
          trucksWithCoordinates++;
          newMarkers.add(
            Marker(
              markerId: MarkerId(truck.id),
              position: LatLng(truck.latitude!, truck.longitude!),
              infoWindow: InfoWindow(
                title: truck.name,
                snippet: '${truck.isOpen ? "🟢 Open" : "🔴 Closed"} • ⭐ ${truck.rating.toStringAsFixed(1)}',
                onTap: () => _showTruckDetails(truck),
              ),
              icon: truck.isOpen 
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              onTap: () => _showTruckDetails(truck),
            ),
          );
        } else {
          trucksWithoutCoordinates++;
          debugPrint('🗺️ Truck without coordinates: ${truck.name} (${truck.id})');
        }
      }

      debugPrint('🗺️ MAP DEBUG: Trucks with coordinates: $trucksWithCoordinates');
      debugPrint('🗺️ MAP DEBUG: Trucks without coordinates: $trucksWithoutCoordinates');
      debugPrint('🗺️ MAP DEBUG: Total markers created: ${newMarkers.length}');

      setState(() {
        _markers = newMarkers;
      });
    } catch (e) {
      debugPrint('Error updating markers: $e');
    }
  }

  void _showTruckDetails(FoodTruck truck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FoodTruckDetailScreen(truck: truck),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      _mapController = controller;
      setState(() {
        _mapInitialized = true;
      });
      
      // Move to user's location or default location
      _moveToUserLocation();
      
      // Show API key help message if needed
      if (mounted) {
        Timer(const Duration(seconds: 3), () {
          if (mounted && _mapController != null && _markers.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📱 If map is blank, you may need a Google Maps API key'),
                duration: Duration(seconds: 5),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _mapError = 'Map initialization failed: $e';
      });
    }
  }

  Future<void> _moveToUserLocation() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      LatLng targetLocation = _defaultLocation;
      
      if (locationProvider.currentPosition != null) {
        targetLocation = LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
      }

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetLocation,
            zoom: 13.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error moving to user location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Truck Map'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
              await locationProvider.getCurrentLocation();
              await _moveToUserLocation();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎯 Location updated')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
              foodTruckProvider.loadFoodTrucks();
              _updateMarkers();
            },
          ),
        ],
      ),
      body: Consumer3<LocationProvider, FoodTruckProvider, FavoritesProvider>(
        builder: (context, locationProvider, foodTruckProvider, favoritesProvider, child) {
          if (_mapError != null) {
            return _buildErrorWidget();
          }

          if (foodTruckProvider.isLoading) {
            return _buildLoadingWidget();
          }

          final trucksToShow = _showFavoritesOnly 
              ? foodTruckProvider.foodTrucks.where((truck) => favoritesProvider.isFavorite(truck.id)).toList()
              : foodTruckProvider.foodTrucks;

          // Update markers when favorites change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMarkers();
          });

          return Stack(
            children: [
              // Google Map (only on mobile) or Web Fallback
              kIsWeb ? _buildWebMapFallback(trucksToShow, favoritesProvider) : GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: locationProvider.currentPosition != null
                      ? LatLng(
                          locationProvider.currentPosition!.latitude,
                          locationProvider.currentPosition!.longitude,
                        )
                      : _defaultLocation,
                  zoom: 13.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: true,
                onTap: (LatLng position) {
                  // Hide any open info windows when tapping map
                },
              ),
              
              // Map status banner
              if (!_mapInitialized)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Loading map...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Truck count indicator
              if (_mapInitialized)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showFavoritesOnly ? Icons.favorite : Icons.local_shipping,
                          color: _showFavoritesOnly ? Colors.red : Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${trucksToShow.length} ${_showFavoritesOnly ? "favorites" : "trucks"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showFavoritesOnly = !_showFavoritesOnly;
          });
          _updateMarkers();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_showFavoritesOnly 
                    ? '❤️ Showing favorite trucks only' 
                    : '🚚 Showing all trucks'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        backgroundColor: _showFavoritesOnly ? Colors.red : null,
        child: Icon(_showFavoritesOnly ? Icons.favorite : Icons.filter_list),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading food trucks...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Map Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _mapError ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _mapError = null;
                  _mapInitialized = false;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebMapFallback(List<FoodTruck> trucksToShow, FavoritesProvider favoritesProvider) {
    return Column(
      children: [
        // Web notice banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Map (Mobile Only)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Download the mobile app for full map functionality',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Food truck list view for web
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trucksToShow.length,
            itemBuilder: (context, index) {
              final truck = trucksToShow[index];
              final isFavorite = favoritesProvider.isFavorite(truck.id);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: truck.isOpen ? Colors.green : Colors.red,
                    child: Icon(
                      Icons.local_dining,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    truck.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(truck.description),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: truck.isOpen ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              truck.isOpen ? 'Open' : 'Closed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${truck.rating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (truck.address != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                truck.address!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return IconButton(
                        onPressed: () async {
                          if (authProvider.user?.id != null) {
                            await favoritesProvider.toggleFavorite(
                              authProvider.user!.id,
                              truck.id,
                            );
                          }
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FoodTruckDetailScreen(truck: truck),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 
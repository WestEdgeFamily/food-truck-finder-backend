import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
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
  Set<Marker> _markers = {};
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(40.7589, -73.9851), // New York City
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);

    // Get current location
    await locationProvider.getCurrentLocation();
    
    // Load food trucks if not already loaded
    if (foodTruckProvider.foodTrucks.isEmpty) {
      await foodTruckProvider.loadFoodTrucks();
    }

    // Update camera position to user's location
    if (locationProvider.currentPosition != null && _mapController != null) {
      final userLocation = locationProvider.currentPosition!;
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(userLocation.latitude, userLocation.longitude),
        ),
      );
    }

    _updateMarkers();
  }

  void _updateMarkers() {
    final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    Set<Marker> markers = {};

    // Add user location marker
    if (locationProvider.currentPosition != null) {
      final userLocation = locationProvider.currentPosition!;
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLocation.latitude, userLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
    }

    // Add food truck markers
    for (final truck in foodTruckProvider.foodTrucks) {
      if (truck.hasLocation) {
        final isFavorite = favoritesProvider.isFavorite(truck.id);
        markers.add(
          Marker(
            markerId: MarkerId(truck.id),
            position: LatLng(truck.latitude!, truck.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isFavorite ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: truck.name,
              snippet: '${truck.isOpen ? "Open" : "Closed"} • ${truck.rating.toStringAsFixed(1)}⭐',
            ),
            onTap: () => _showTruckBottomSheet(truck),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showTruckBottomSheet(FoodTruck truck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Truck header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              truck.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              truck.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Consumer2<FavoritesProvider, AuthProvider>(
                        builder: (context, favoritesProvider, authProvider, child) {
                          final isFavorite = favoritesProvider.isFavorite(truck.id);
                          return IconButton(
                            onPressed: () async {
                              if (authProvider.user?.id != null) {
                                await favoritesProvider.toggleFavorite(
                                  authProvider.user!.id,
                                  truck.id,
                                );
                                _updateMarkers(); // Update marker colors
                              }
                            },
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status and rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: truck.isOpen ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          truck.isOpen ? 'Open Now' : 'Closed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${truck.rating.toStringAsFixed(1)} (${truck.reviewCount} reviews)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Cuisine types
                  Wrap(
                    spacing: 8,
                    children: truck.cuisineTypes.map((cuisine) {
                      return Chip(
                        label: Text(cuisine),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          truck.address ?? 'Location available',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FoodTruckDetailScreen(truck: truck),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Add navigation functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navigate to ${truck.name}')),
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Truck Map'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
              await locationProvider.getCurrentLocation();
              if (locationProvider.currentPosition != null && _mapController != null) {
                final userLocation = locationProvider.currentPosition!;
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(userLocation.latitude, userLocation.longitude),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
              foodTruckProvider.loadFoodTrucks().then((_) => _updateMarkers());
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Map Feature Temporarily Disabled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Requires Google Maps API setup',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Toggle between favorite trucks only and all trucks
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Filter feature coming soon!')),
          );
        },
        child: const Icon(Icons.filter_list),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../models/food_truck.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/customer/food_truck_detail_screen.dart';

class FoodTruckCard extends StatelessWidget {
  final FoodTruck foodTruck;
  final Position? currentLocation;

  const FoodTruckCard({
    super.key,
    required this.foodTruck,
    this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showFoodTruckDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with favorite button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: foodTruck.image != null
                        ? CachedNetworkImage(
                            imageUrl: foodTruck.image!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                // Favorite button positioned in top-right corner
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer2<FavoritesProvider, AuthProvider>(
                    builder: (context, favoritesProvider, authProvider, child) {
                      final isFavorite = favoritesProvider.isFavorite(foodTruck.id);
                      
                      return GestureDetector(
                        onTap: () async {
                          if (authProvider.user != null) {
                            await favoritesProvider.toggleFavorite(authProvider.user!.id, foodTruck.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavorite 
                                      ? '${foodTruck.name} removed from favorites'
                                      : '${foodTruck.name} added to favorites'
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to add favorites'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey[600],
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          foodTruck.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: foodTruck.isOpen ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          foodTruck.isOpen ? 'Open' : 'Closed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Business name
                  if (foodTruck.businessName != foodTruck.name)
                    Text(
                      foodTruck.businessName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    foodTruck.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Cuisine types
                  if (foodTruck.cuisineTypes.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: foodTruck.cuisineTypes.take(3).map((cuisine) {
                        return Chip(
                          label: Text(
                            cuisine,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  
                  // Rating and distance row
                  Row(
                    children: [
                      // Rating
                      if (foodTruck.rating > 0) ...[
                        RatingBarIndicator(
                          rating: foodTruck.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${foodTruck.rating.toStringAsFixed(1)} (${foodTruck.reviewCount})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const Spacer(),
                      
                      // Distance
                      if (_getDistance() != null) ...[
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(_getDistance()!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Address
                  if (foodTruck.address != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            foodTruck.address!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.local_shipping,
          size: 48,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  double? _getDistance() {
    if (currentLocation == null || !foodTruck.hasLocation) return null;
    
    return Geolocator.distanceBetween(
      currentLocation!.latitude,
      currentLocation!.longitude,
      foodTruck.latitude!,
      foodTruck.longitude!,
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  void _showFoodTruckDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FoodTruckDetailScreen(truck: foodTruck),
      ),
    );
  }
} 
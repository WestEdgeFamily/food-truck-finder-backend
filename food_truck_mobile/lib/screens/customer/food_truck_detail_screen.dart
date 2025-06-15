import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_truck.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';

class FoodTruckDetailScreen extends StatelessWidget {
  final FoodTruck truck;

  const FoodTruckDetailScreen({super.key, required this.truck});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(truck.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer2<FavoritesProvider, AuthProvider>(
            builder: (context, favoritesProvider, authProvider, child) {
              final isFavorite = favoritesProvider.isFavorite(truck.id);
              return favoritesProvider.isActionLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: () async {
                        if (authProvider.user?.id != null) {
                          final success = await favoritesProvider.toggleFavorite(
                            authProvider.user!.id,
                            truck.id,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Added to favorites'
                                      : 'Removed from favorites',
                                ),
                                backgroundColor: success ? Colors.green : Colors.orange,
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please sign in to add favorites'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                    );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truck.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      truck.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cuisine Types
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuisine Types',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: truck.cuisineTypes.map((cuisine) {
                        return Chip(
                          label: Text(cuisine),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Info
            if (truck.hasLocation) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Add navigation functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navigate to ${truck.name}')),
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Get Directions'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Contact Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (truck.phone != null) ...[
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(truck.phone!),
                        trailing: IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${truck.phone}...')),
                            );
                          },
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    if (truck.email != null) ...[
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(truck.email!),
                        trailing: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Email ${truck.email}...')),
                            );
                          },
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/food_truck.dart';
import 'food_truck_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    
    if (authProvider.user?.id != null) {
      await favoritesProvider.checkEndpointAvailability();
      await favoritesProvider.loadFavorites(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Food Trucks'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: Consumer2<FavoritesProvider, AuthProvider>(
        builder: (context, favoritesProvider, authProvider, child) {
          // Show error if any
          if (favoritesProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading favorites',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          favoritesProvider.error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red[800],
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _loadFavorites,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show loading indicator
          if (favoritesProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeBounce(
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your favorites...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Show empty state
          if (favoritesProvider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite food trucks yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start exploring and save your favorites!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Food Trucks'),
                  ),
                ],
              ),
            );
          }

          // Show favorites list
          return RefreshIndicator(
            onRefresh: _loadFavorites,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoritesProvider.favorites.length,
              itemBuilder: (context, index) {
                final truck = favoritesProvider.favorites[index];
                return _buildFavoriteCard(context, truck, authProvider.user!.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, FoodTruck truck, String userId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodTruckDetailScreen(truck: truck),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food truck image
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: truck.image != null
                  ? Image.network(
                      truck.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_shipping,
                          size: 48,
                          color: Colors.grey[400],
                        );
                      },
                    )
                  : Icon(
                      Icons.local_shipping,
                      size: 48,
                      color: Colors.grey[400],
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and favorite button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          truck.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          return favoritesProvider.isActionLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  onPressed: () async {
                                    await favoritesProvider.toggleFavorite(userId, truck.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Removed from favorites'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                  ),
                                );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    truck.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Additional info
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        truck.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          truck.address ?? 'Location not available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
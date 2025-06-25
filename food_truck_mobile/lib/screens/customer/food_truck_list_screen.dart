import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/food_truck_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/food_truck.dart';
import '../../widgets/food_truck_card.dart';

class FoodTruckListScreen extends StatefulWidget {
  const FoodTruckListScreen({super.key});

  @override
  State<FoodTruckListScreen> createState() => _FoodTruckListScreenState();
}

class _FoodTruckListScreenState extends State<FoodTruckListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set up callback to clear search text when filters are cleared programmatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
      foodTruckProvider.setOnFiltersClearedCallback(() {
        if (mounted) {
          _searchController.clear();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // FIX FOR BUG #1 IMPROVEMENT - Clear search when leaving this screen
    Provider.of<FoodTruckProvider>(context, listen: false).clearFilters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Trucks'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black), // Fix text color
              decoration: InputDecoration(
                hintText: 'Search food trucks...',
                hintStyle: TextStyle(color: Colors.grey[600]), // Fix hint color
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _performSearch,
            ),
          ),
          
          // Food truck list
          Expanded(
            child: Consumer2<FoodTruckProvider, LocationProvider>(
              builder: (context, foodTruckProvider, locationProvider, child) {
                if (foodTruckProvider.isLoading) {
                  return Center(
                    child: SpinKitThreeBounce(
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                  );
                }

                if (foodTruckProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading food trucks',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          foodTruckProvider.error!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => foodTruckProvider.loadFoodTrucks(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final foodTrucks = foodTruckProvider.foodTrucks;

                if (foodTrucks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No food trucks found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => foodTruckProvider.loadFoodTrucks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: foodTrucks.length,
                    itemBuilder: (context, index) {
                      final truck = foodTrucks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FoodTruckCard(
                          foodTruck: truck,
                          currentLocation: locationProvider.currentPosition,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    Provider.of<FoodTruckProvider>(context, listen: false).searchTrucks(query);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Food Trucks'),
        content: Consumer<FoodTruckProvider>(
          builder: (context, provider, child) {
            final availableCuisines = provider.availableCuisines;
            final selectedCuisines = provider.selectedCuisines;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cuisine Types:'),
                const SizedBox(height: 8),
                ...availableCuisines.map((cuisine) {
                  return CheckboxListTile(
                    title: Text(cuisine),
                    value: selectedCuisines.contains(cuisine),
                    onChanged: (selected) {
                      final newSelected = List<String>.from(selectedCuisines);
                      if (selected == true) {
                        newSelected.add(cuisine);
                      } else {
                        newSelected.remove(cuisine);
                      }
                      provider.filterByCuisines(newSelected);
                    },
                  );
                }),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<FoodTruckProvider>(context, listen: false).clearFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
} 
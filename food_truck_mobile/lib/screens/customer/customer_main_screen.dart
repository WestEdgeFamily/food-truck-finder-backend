import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_truck_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/location_monitoring_provider.dart';
import '../../providers/favorites_provider.dart';
import 'food_truck_list_screen.dart';
import 'food_truck_map_screen.dart';
import 'customer_profile_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop location monitoring when screen is disposed
    final locationMonitoringProvider = Provider.of<LocationMonitoringProvider>(context, listen: false);
    locationMonitoringProvider.stopLocationMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final locationMonitoringProvider = Provider.of<LocationMonitoringProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground, restart monitoring if needed
        if (authProvider.user?.id != null) {
          _restartLocationMonitoring();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is in background, continue monitoring in background
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _restartLocationMonitoring() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final locationMonitoringProvider = Provider.of<LocationMonitoringProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user?.id != null) {
      await locationMonitoringProvider.startLocationMonitoring(
        locationProvider: locationProvider,
        favoritesProvider: favoritesProvider,
        userId: authProvider.user!.id,
      );
    }
  }

  Future<void> _loadInitialData() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final locationMonitoringProvider = Provider.of<LocationMonitoringProvider>(context, listen: false);
    final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Request location permission and get current location
    await locationProvider.requestLocationPermission();
    await locationProvider.getCurrentLocation();
    
    // Initialize location monitoring
    await locationMonitoringProvider.initialize();
    
    // Load food trucks
    await foodTruckProvider.loadFoodTrucks();
    
    // Load user's favorites (with error handling)
    if (authProvider.user?.id != null) {
      try {
        await favoritesProvider.loadFavorites(authProvider.user!.id);
        
        // Start location monitoring for favorite trucks
        await locationMonitoringProvider.startLocationMonitoring(
          locationProvider: locationProvider,
          favoritesProvider: favoritesProvider,
          userId: authProvider.user!.id,
        );
      } catch (e) {
        debugPrint('Failed to load favorites: $e');
        // Continue without favorites - don't crash the app
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Food Trucks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      const FoodTruckListScreen(),
      const FoodTruckMapScreen(),
      const CustomerProfileScreen(),
    ];
  }
} 
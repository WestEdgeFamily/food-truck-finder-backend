import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/location_monitoring_provider.dart';
import 'providers/food_truck_provider.dart';
import 'providers/favorites_provider.dart';
import 'utils/theme.dart';

void main() {
  runApp(const FoodTruckApp());
}

class FoodTruckApp extends StatelessWidget {
  const FoodTruckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => LocationMonitoringProvider()),
        ChangeNotifierProvider(create: (_) => FoodTruckProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Food Truck Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

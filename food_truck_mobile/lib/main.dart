import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/location_monitoring_provider.dart';
import 'providers/food_truck_provider.dart';
import 'providers/favorites_provider.dart';
import 'utils/theme.dart';
import 'config/app_config.dart';
import 'services/analytics_service.dart';
import 'services/network_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set up Crashlytics
  if (AppConfig.enableCrashlytics) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
  }
  
  // Initialize services
  analyticsService.initialize();
  networkService.initialize();
  
  // Log app open
  await analyticsService.logAppOpen();
  
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

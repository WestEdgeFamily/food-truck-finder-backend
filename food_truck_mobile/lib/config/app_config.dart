// SECURE CONFIGURATION TEMPLATE
// This file should use environment variables in production

class AppConfig {
  // API Configuration
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://food-truck-finder-api.onrender.com/api',
  );

  // Google Maps - DO NOT hardcode keys here!
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '', // Empty in code, set via build command
  );

  // POS System OAuth Configurations
  static const Map<String, String> posClientIds = {
    'square': String.fromEnvironment('SQUARE_CLIENT_ID', defaultValue: ''),
    'toast': String.fromEnvironment('TOAST_CLIENT_ID', defaultValue: ''),
    'clover': String.fromEnvironment('CLOVER_CLIENT_ID', defaultValue: ''),
    'shopify': String.fromEnvironment('SHOPIFY_CLIENT_ID', defaultValue: ''),
    'touchbistro': String.fromEnvironment('TOUCHBISTRO_CLIENT_ID', defaultValue: ''),
  };

  // Social Media OAuth
  static const String facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: '',
  );
  
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID', 
    defaultValue: '',
  );

  // Feature Flags
  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
  );
  
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  // Build Configuration
  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );

  // Timeouts and Limits
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  // Cache Configuration  
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
}

// Usage in build commands:
// flutter build apk --release \
//   --dart-define=API_URL=https://your-api.com/api \
//   --dart-define=GOOGLE_MAPS_API_KEY=your-key \
//   --dart-define=SQUARE_CLIENT_ID=your-square-id \
//   --dart-define=ENABLE_CRASHLYTICS=true
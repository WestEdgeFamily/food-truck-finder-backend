class Environment {
  static const String appName = 'Food Truck Finder';
  
  // API Configuration
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  // Use these environment variables during build:
  // flutter build apk --dart-define=API_URL=https://your-api.com
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: isProduction 
      ? 'https://food-truck-finder-api.onrender.com/api'
      : 'http://localhost:3001/api',
  );
  
  // OAuth Configuration (set during build)
  static const String facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID', defaultValue: '');
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
  
  // Feature Flags
  static const bool enablePushNotifications = bool.fromEnvironment('ENABLE_PUSH', defaultValue: true);
  static const bool enableSocialLogin = bool.fromEnvironment('ENABLE_SOCIAL_LOGIN', defaultValue: true);
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
  
  // Map Configuration
  static const double defaultLatitude = 40.7128; // NYC
  static const double defaultLongitude = -74.0060;
  static const double defaultZoom = 12.0;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Configuration
  static const Duration cacheValidDuration = Duration(hours: 1);
  static const int maxCacheSize = 50 * 1024 * 1024; // 50 MB
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxReviewLength = 500;
  
  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB
  static const int imageQuality = 85;
  static const double thumbnailSize = 150.0;
}
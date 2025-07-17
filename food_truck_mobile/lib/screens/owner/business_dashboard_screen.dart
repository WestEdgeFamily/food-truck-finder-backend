import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_truck_provider.dart';
import '../../services/api_service.dart';
import '../../models/food_truck.dart';
import '../../models/social_account.dart';
import '../../models/social_post.dart';
import '../../models/review.dart';
import 'social_media_dashboard_screen.dart';
import 'social_media/post_composer_screen.dart';
import 'review_management_screen.dart';
import 'owner_profile_screen.dart';
import 'menu_management_screen.dart';
import 'pos_integration_screen.dart';
import 'schedule_management_screen.dart';
import 'analytics_screen.dart';
import 'truck_profile_screen.dart';
import 'advanced_schedule_screen.dart';
import 'automated_posting_settings_screen.dart';
import '../../services/automated_posting_service.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;
  FoodTruck? _currentTruck;
  Timer? _refreshTimer;
  
  // Social media data
  List<SocialAccount> _connectedAccounts = [];
  List<SocialPost> _recentPosts = [];
  
  // Review data
  List<Review> _recentReviews = [];
  ReviewStats? _reviewStats;
  
  @override
  void initState() {
    super.initState();
    _loadTruckData();
    
    // Refresh truck data every 60 seconds to catch automatic schedule updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _loadTruckData();
        // Check for automated posting
        if (_currentTruck != null) {
          AutomatedPostingService.checkAndPostScheduledMessages(_currentTruck!.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTruckData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
      
      // Load all trucks and find the one owned by current user
      await foodTruckProvider.loadFoodTrucks();
      
      // Find truck by ownerId
      FoodTruck? userTruck = foodTruckProvider.allFoodTrucks.cast<FoodTruck?>().firstWhere(
        (truck) => truck?.ownerId == authProvider.user?.id,
        orElse: () => null,
      );
      
      // If no truck found, try to find by business name match
      if (userTruck == null && authProvider.user?.businessName != null) {
        userTruck = foodTruckProvider.allFoodTrucks.cast<FoodTruck?>().firstWhere(
          (truck) => truck?.businessName == authProvider.user?.businessName,
          orElse: () => null,
        );
      }
      
      setState(() {
        _currentTruck = userTruck;
      });
      
      // Load social media and review data if truck exists
      if (userTruck?.id != null) {
        await _loadSocialMediaData(userTruck!.id);
        await _loadReviewData(userTruck!.id);
        
        // Check if we should post opening message
        AutomatedPostingService.checkAndPostScheduledMessages(userTruck.id);
      }
    } catch (e) {
      debugPrint('Error loading truck data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading truck data: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOpenStatus() async {
    if (_currentTruck == null) return;
    
    setState(() => _isUpdating = true);
    
    try {
      final newStatus = !_currentTruck!.isOpen;
      final response = await ApiService.updateTruckStatus(_currentTruck!.id, newStatus);
      
      if (response['success'] == true) {
        setState(() {
          _currentTruck = _currentTruck!.copyWith(isOpen: newStatus);
        });
        
        // Refresh the food truck provider
        final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
        await foodTruckProvider.loadFoodTrucks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus ? 'Food truck is now OPEN!' : 'Food truck is now CLOSED!'
              ),
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      debugPrint('Error updating truck status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _loadSocialMediaData(String truckId) async {
    try {
      // Load connected accounts - handle API response gracefully
      try {
        final accountsData = await ApiService.getSocialAccounts(truckId);
        _connectedAccounts = [];
        // API may return empty Map instead of List, so handle gracefully
      } catch (e) {
        debugPrint('Error loading social accounts: $e');
        _connectedAccounts = [];
      }

      // Load recent posts
      final postsData = await ApiService.getSocialPosts(
        truckId,
        limit: 3,
      );
      _recentPosts = (postsData['posts'] as List)
          .map((data) => SocialPost.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error loading social media data: $e');
      // Don't show error for social media - it's optional
    }
  }

  Future<void> _loadReviewData(String truckId) async {
    try {
      // Load recent reviews
      final reviewsResponse = await ApiService.getTruckReviews(
        truckId,
        page: 1,
        limit: 3,
      );
      
      _recentReviews = (reviewsResponse['reviews'] as List)
          .map((data) => Review.fromJson(data))
          .toList();
      
      if (reviewsResponse['stats'] != null) {
        // Create a simple review stats object to avoid import conflict
        final stats = reviewsResponse['stats'];
        _reviewStats = ReviewStats(
          totalReviews: stats['totalReviews'] ?? 0,
          averageRating: (stats['averageRating'] ?? 0.0).toDouble(),
          respondedReviews: stats['respondedReviews'] ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Error loading review data: $e');
      // Don't show error for reviews - it's optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OwnerProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: _loadTruckData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: (_currentTruck?.isOpen ?? false) ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  (_currentTruck?.isOpen ?? false) ? Icons.store : Icons.store_mall_directory_outlined,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentTruck?.name ?? 'Your Food Truck',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (_currentTruck?.isOpen ?? false) ? 'Currently OPEN' : 'Currently CLOSED',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: (_currentTruck?.isOpen ?? false) ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getScheduleStatusText(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Schedule Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Status automatically updates based on your schedule. Use the button below to override manually.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Open/Close Toggle Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUpdating ? null : _toggleOpenStatus,
                              icon: _isUpdating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      (_currentTruck?.isOpen ?? false) ? Icons.close : Icons.store,
                                    ),
                              label: Text(
                                _isUpdating
                                    ? 'Updating...'
                                    : (_currentTruck?.isOpen ?? false) 
                                        ? 'Override: Close Now' 
                                        : 'Override: Open Now',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_currentTruck?.isOpen ?? false) ? Colors.red : Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Stats
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Stats',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Rating',
                                  '${_currentTruck?.rating.toStringAsFixed(1) ?? '0.0'} ⭐',
                                  Icons.star,
                                  Colors.amber,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Reviews',
                                  '${_currentTruck?.reviewCount ?? 0}',
                                  Icons.rate_review,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Social Media Management
                  _buildSocialMediaSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Review Management
                  _buildReviewManagementSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Manage Reviews',
                                  Icons.rate_review,
                                  Colors.purple,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ReviewManagementScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  'Manage Menu',
                                  Icons.restaurant_menu,
                                  Colors.orange,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const MenuManagementScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'POS Integration',
                                  Icons.point_of_sale,
                                  Colors.green,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PosIntegrationScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  'Schedule Manager',
                                  Icons.calendar_month,
                                  Colors.orange,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AdvancedScheduleScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Analytics',
                                  Icons.analytics,
                                  Colors.blue,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AnalyticsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  'Truck Profile',
                                  Icons.edit,
                                  Colors.purple,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TruckProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Post Opening',
                                  Icons.campaign,
                                  Colors.teal,
                                  () => _postOpeningMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  'Auto Post Settings',
                                  Icons.settings,
                                  Colors.grey,
                                  () {
                                    if (_currentTruck != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AutomatedPostingSettingsScreen(
                                            truckId: _currentTruck!.id,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _postOpeningMessage() async {
    if (_currentTruck == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No truck data available')),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Opening Message'),
        content: const Text(
          'This will post your truck\'s opening hours and location to all connected social media accounts.\n\n'
          'Make sure your truck is actually open before posting!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Post Now'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Posting to social media...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      // Get today's schedule
      final now = DateTime.now();
      final dayOfWeek = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'][now.weekday % 7];
      final todaySchedule = _currentTruck!.schedule?[dayOfWeek];
      
      if (todaySchedule == null || !todaySchedule['isOpen']) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your truck is not scheduled to be open today')),
        );
        return;
      }
      
      final openTime = todaySchedule['openTime'] ?? '9:00';
      final closeTime = todaySchedule['closeTime'] ?? '17:00';
      
      // Get current location
      String location = _currentTruck!.address ?? 'Check our app for location';
      try {
        final locationData = await ApiService.getTruckLocations(_currentTruck!.id);
        final locations = locationData['locations'] as List? ?? [];
        if (locations.isNotEmpty) {
          final currentLocation = locations.first;
          location = currentLocation['address'] ?? currentLocation['name'] ?? location;
        }
      } catch (e) {
        debugPrint('Could not get location: $e');
      }
      
      // Get today's specials
      List<String> specials = [];
      try {
        final menuData = await ApiService.getMenuItems(_currentTruck!.id);
        final items = menuData['items'] as List? ?? [];
        specials = items
            .where((item) => item['isFeatured'] == true || item['isSpecial'] == true)
            .take(3)
            .map((item) => '${item['name']} - \$${item['price']}')
            .toList();
      } catch (e) {
        debugPrint('Could not get specials: $e');
      }
      
      // Create message
      final message = await AutomatedPostingService.createOpeningMessage(
        truckName: _currentTruck!.name,
        location: location,
        openTime: _formatTime(openTime),
        closeTime: _formatTime(closeTime),
        cuisine: _currentTruck!.cuisineTypes.isNotEmpty ? _currentTruck!.cuisineTypes.first : null,
        specialsToday: specials,
        truckId: _currentTruck!.id,
      );
      
      // Post to all platforms
      final result = await AutomatedPostingService.postToAllConnectedPlatforms(
        truckId: _currentTruck!.id,
        message: message,
        imageUrl: _currentTruck!.image,
      );
      
      Navigator.pop(context); // Close loading dialog
      
      if (result['success'] == true) {
        final successCount = (result['results'] as Map).values
            .where((r) => r['success'] == true)
            .length;
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posted to $successCount social media platforms!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  

  String _getScheduleStatusText() {
    if (_currentTruck?.schedule == null) {
      return 'No schedule set - truck will stay in current state';
    }

    final now = DateTime.now();
    final currentDay = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'][now.weekday % 7];
    final schedule = _currentTruck!.schedule!;
    final todaySchedule = schedule[currentDay];

    if (todaySchedule == null || todaySchedule['isOpen'] != true) {
      // Find next open day
      for (int i = 1; i <= 7; i++) {
        final nextDayIndex = (now.weekday + i - 1) % 7;
        final nextDay = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'][nextDayIndex];
        final nextDaySchedule = schedule[nextDay];
        
        if (nextDaySchedule != null && nextDaySchedule['isOpen'] == true) {
          final dayName = nextDay[0].toUpperCase() + nextDay.substring(1);
          return 'Next opens: $dayName at ${_formatTime(nextDaySchedule['open'])}';
        }
      }
      return 'No upcoming open schedule found';
    }

    final openTime = todaySchedule['open'] as String;
    final closeTime = todaySchedule['close'] as String;
    final currentMinutes = now.hour * 60 + now.minute;
    
    final openMinutes = _timeStringToMinutes(openTime);
    final closeMinutes = _timeStringToMinutes(closeTime);

    if (_currentTruck!.isOpen) {
      return 'Closes today at ${_formatTime(closeTime)}';
    } else {
      if (currentMinutes < openMinutes) {
        return 'Opens today at ${_formatTime(openTime)}';
      } else {
        // Find next open day
        for (int i = 1; i <= 7; i++) {
          final nextDayIndex = (now.weekday + i - 1) % 7;
          final nextDay = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'][nextDayIndex];
          final nextDaySchedule = schedule[nextDay];
          
          if (nextDaySchedule != null && nextDaySchedule['isOpen'] == true) {
            final dayName = nextDay[0].toUpperCase() + nextDay.substring(1);
            return 'Next opens: $dayName at ${_formatTime(nextDaySchedule['open'])}';
          }
        }
        return 'No upcoming open schedule';
      }
    }
  }

  int _timeStringToMinutes(String timeString) {
    final parts = timeString.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '$displayHour:$displayMinute $period';
  }

  Widget _buildSocialMediaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Social Media Manager',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_currentTruck?.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SocialMediaDashboardScreen(
                            truckId: _currentTruck!.id,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quick Social Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Create Post',
                    Icons.edit,
                    Colors.blue,
                    () {
                      if (_currentTruck?.id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostComposerScreen(
                              truckId: _currentTruck!.id,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Social Analytics',
                    Icons.insights,
                    Colors.green,
                    () {
                      if (_currentTruck?.id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SocialMediaDashboardScreen(
                              truckId: _currentTruck!.id,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Connected Accounts Summary
            if (_connectedAccounts.isNotEmpty) ...[
              Text(
                'Connected Accounts (${_connectedAccounts.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _connectedAccounts.take(3).map((account) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: _getSocialPlatformColor(account.platform),
                      child: Icon(
                        _getSocialPlatformIcon(account.platform),
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    label: Text(
                      account.accountName ?? account.platformDisplayName,
                      style: const TextStyle(fontSize: 10),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.link_off, size: 32, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No social accounts connected',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Connect Account'),
                      onPressed: () {
                        if (_currentTruck?.id != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SocialMediaDashboardScreen(
                                truckId: _currentTruck!.id,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewManagementScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Review Stats Row
            if (_reviewStats != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildReviewStatCard(
                      'Total Reviews',
                      _reviewStats!.totalReviews.toString(),
                      Icons.rate_review,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReviewStatCard(
                      'Avg Rating',
                      '${_reviewStats!.averageRating.toStringAsFixed(1)} ⭐',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReviewStatCard(
                      'Pending',
                      '${_reviewStats!.totalReviews - (_reviewStats!.respondedReviews ?? 0)}',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Quick Review Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Respond to Reviews',
                    Icons.reply,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReviewManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'Review Analytics',
                    Icons.analytics,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReviewManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Recent Reviews Summary
            if (_recentReviews.isNotEmpty) ...[
              Text(
                'Recent Reviews (${_recentReviews.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: _recentReviews.take(2).map((review) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < review.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 12,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review.comment.length > 100
                              ? '${review.comment.substring(0, 100)}...'
                              : review.comment,
                          style: const TextStyle(fontSize: 11),
                        ),
                        if (review.response == null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Needs Response',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 32, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Encourage customers to leave reviews!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Color _getSocialPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Colors.pink;
      case 'facebook':
        return Colors.blue;
      case 'twitter':
        return Colors.lightBlue;
      case 'linkedin':
        return Colors.blueGrey;
      case 'tiktok':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  IconData _getSocialPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.tag;
      case 'linkedin':
        return Icons.business;
      case 'tiktok':
        return Icons.music_note;
      default:
        return Icons.share;
    }
  }
}

// Simple ReviewStats class to avoid import conflicts
class ReviewStats {
  final int totalReviews;
  final double averageRating;
  final int respondedReviews;

  ReviewStats({
    required this.totalReviews,
    required this.averageRating,
    required this.respondedReviews,
  });
} 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_truck_provider.dart';
import '../../services/api_service.dart';
import '../../models/food_truck.dart';

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
  
  @override
  void initState() {
    super.initState();
    _loadTruckData();
    
    // Refresh truck data every 60 seconds to catch automatic schedule updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _loadTruckData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
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
                                  'Update Location',
                                  Icons.location_on,
                                  Colors.blue,
                                  () => Navigator.pushNamed(context, '/owner/location-tracking'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  'Manage Menu',
                                  Icons.restaurant_menu,
                                  Colors.orange,
                                  () => Navigator.pushNamed(context, '/owner/menu-management'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Schedule',
                                  Icons.schedule,
                                  Colors.green,
                                  () => Navigator.pushNamed(context, '/owner/schedule-management'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  'Analytics',
                                  Icons.analytics,
                                  Colors.purple,
                                  () => Navigator.pushNamed(context, '/owner/analytics'),
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
} 
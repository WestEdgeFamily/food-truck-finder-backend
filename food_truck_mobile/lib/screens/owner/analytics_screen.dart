import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/food_truck.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'This Week';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];
  
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get user's food truck from API
      final trucks = await ApiService.getFoodTrucks();
      final userTruck = trucks.firstWhere(
        (truck) {
          if (truck is Map<String, dynamic>) {
            final foodTruck = FoodTruck.fromJson(truck);
            return foodTruck.ownerId == userId;
          }
          return false;
        },
        orElse: () => null,
      );
      
      if (userTruck != null) {
        final foodTruck = FoodTruck.fromJson(userTruck);
        final analyticsResponse = await ApiService.getAnalytics(foodTruck.id);
        
        setState(() {
          _analyticsData = analyticsResponse['analytics'];
        });
      } else {
        throw Exception('No food truck found for user');
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() {
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => _periods
                .map((period) => PopupMenuItem(
                      value: period,
                      child: Text(period),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading analytics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _analyticsData == null
                  ? const Center(child: Text('No analytics data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overview Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Total Views',
                                  _analyticsData!['totalViews'].toString(),
                                  Icons.visibility,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Favorites',
                                  _analyticsData!['totalFavorites'].toString(),
                                  Icons.favorite,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Avg Rating',
                                  _analyticsData!['averageRating'].toString(),
                                  Icons.star,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Reviews',
                                  _analyticsData!['totalReviews'].toString(),
                                  Icons.rate_review,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Weekly Views Chart
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Weekly Views',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: _buildWeeklyChart(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Monthly Revenue (if available)
                          if (_analyticsData!['monthlyRevenue'] != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly Revenue',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...(_analyticsData!['monthlyRevenue'] as List).map((month) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              child: Text(month['month']),
                                            ),
                                            Expanded(
                                              child: LinearProgressIndicator(
                                                value: month['revenue'] / 5000.0,
                                                backgroundColor: Colors.grey[300],
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.green,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('\$${month['revenue']}'),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_analyticsData == null || _analyticsData!['weeklyViews'] == null) {
      return const Center(child: Text('No chart data available'));
    }
    
    final weeklyViews = _analyticsData!['weeklyViews'] as List;
    
    // Handle both array of numbers and array of objects
    List<int> values = [];
    if (weeklyViews.isNotEmpty) {
      if (weeklyViews[0] is int || weeklyViews[0] is double) {
        // Array of numbers: [43,32,43,17,49,43,59]
        values = weeklyViews.map((v) => (v as num).toInt()).toList();
      } else if (weeklyViews[0] is Map) {
        // Array of objects: [{views: 43, day: "Mon"}, ...]
        values = weeklyViews.map((day) => (day['views'] as num).toInt()).toList();
      }
    }
    
    if (values.isEmpty) {
      return const Center(child: Text('No chart data available'));
    }
    
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (index) {
        final value = values[index];
        final day = index < days.length ? days[index] : 'Day ${index + 1}';
        final height = maxValue > 0 ? (value / maxValue) * 150.0 : 0.0;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }),
    );
  }
} 
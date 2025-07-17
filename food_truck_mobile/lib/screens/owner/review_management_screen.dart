import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/review.dart';
import '../../widgets/review_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  List<Review> _reviews = [];
  ReviewStats? _stats;
  bool _isLoading = true;
  String? _error;
  String? _currentTruckId;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreReviews();
    }
  }

  Future<void> _initializeScreen() async {
    await _findUserTruck();
    if (_currentTruckId != null) {
      await _loadReviews();
    }
  }

  Future<void> _findUserTruck() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final businessName = authProvider.user?.businessName;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint('🔍 Looking for truck with owner ID: $userId or business name: $businessName');
      
      // Get user's food truck ID from API
      final trucks = await ApiService.getFoodTrucks();
      Map<String, dynamic>? userTruck;
      
      for (var truck in trucks) {
        if (truck is Map<String, dynamic>) {
          final ownerId = truck['ownerId'] ?? truck['owner'];
          final truckBusinessName = truck['businessName'] ?? truck['name'];
          
          if (ownerId == userId || 
              (businessName != null && truckBusinessName == businessName)) {
            userTruck = truck;
            debugPrint('✅ Found matching truck: ${truck['name']} (ID: ${truck['id'] ?? truck['_id']})');
            break;
          }
        }
      }

      if (userTruck == null) {
        throw Exception('No food truck found. Please register a food truck first.');
      }

      final truckId = userTruck['id'] ?? userTruck['_id'];
      if (truckId == null) {
        throw Exception('Truck ID not found');
      }

      setState(() {
        _currentTruckId = truckId.toString();
      });

    } catch (e) {
      debugPrint('❌ Error finding user truck: $e');
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_currentTruckId == null) {
        await _findUserTruck();
        if (_currentTruckId == null) {
          throw Exception('No food truck found');
        }
      }

      final response = await ApiService.getTruckReviews(
        _currentTruckId!,
        page: 1,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _reviews = (response['reviews'] as List)
              .map((r) => Review.fromJson(r))
              .toList();
          _stats = response['stats'] != null 
              ? ReviewStats.fromJson(response['stats']) 
              : null;
          _currentPage = 1;
          _hasMore = response['pagination']['currentPage'] <
              response['pagination']['totalPages'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_currentTruckId == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await ApiService.getTruckReviews(
        _currentTruckId!,
        page: _currentPage + 1,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _reviews.addAll((response['reviews'] as List)
              .map((r) => Review.fromJson(r))
              .toList());
          _currentPage++;
          _hasMore = response['pagination']['currentPage'] <
              response['pagination']['totalPages'];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more reviews: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: _loadReviews,
      );
    }

    if (_reviews.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.rate_review,
        title: 'No Reviews Yet',
        message: 'Your food truck hasn\'t received any reviews yet. Keep providing great service to earn your first review!',
        actionLabel: 'Refresh',
        onAction: _loadReviews,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Stats Header
          if (_stats != null)
            SliverToBoxAdapter(
              child: _buildStatsHeader(),
            ),
          
          // Reviews List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _reviews.length) {
                  return ReviewCard(
                    review: _reviews[index],
                    isOwner: true,
                    onDeleted: () {
                      setState(() {
                        _reviews.removeAt(index);
                      });
                    },
                    onUpdated: _loadReviews,
                  );
                } else if (_isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return null;
              },
              childCount: _reviews.length + (_isLoadingMore ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsSkeletonLoader(),
        const SizedBox(height: 16),
        ...List.generate(
          5,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonLoader(
              height: 120,
              borderRadius: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Reviews',
                  _stats?.totalReviews.toString() ?? '0',
                  Icons.rate_review,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Average Rating',
                  '${_stats?.averageRating.toStringAsFixed(1) ?? '0.0'} ⭐',
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Responded',
                  _stats?.respondedReviews.toString() ?? '0',
                  Icons.reply,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Pending Response',
                  (_stats != null 
                      ? (_stats!.totalReviews - _stats!.respondedReviews).toString()
                      : '0'),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsSkeletonLoader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          SkeletonLoader(width: 150, height: 20),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 60)),
              SizedBox(width: 16),
              Expanded(child: SkeletonLoader(height: 60)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 60)),
              SizedBox(width: 16),
              Expanded(child: SkeletonLoader(height: 60)),
            ],
          ),
        ],
      ),
    );
  }
}

// ReviewStats class if it doesn't exist
class ReviewStats {
  final int totalReviews;
  final double averageRating;
  final int respondedReviews;

  ReviewStats({
    required this.totalReviews,
    required this.averageRating,
    required this.respondedReviews,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      totalReviews: json['totalReviews'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      respondedReviews: json['respondedReviews'] ?? 0,
    );
  }
} 
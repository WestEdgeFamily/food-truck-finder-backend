import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../models/food_truck.dart';
import '../../services/api_service.dart';
import '../../widgets/review_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import 'add_review_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/star_rating.dart';

class ReviewsScreen extends StatefulWidget {
  final FoodTruck truck;

  const ReviewsScreen({
    super.key,
    required this.truck,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Review> _reviews = [];
  ReviewStats? _stats;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
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

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getTruckReviews(
        widget.truck.id,
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
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    setState(() => _isLoadingMore = true);

    try {
      final response = await ApiService.getTruckReviews(
        widget.truck.id,
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

  Future<void> _addReview() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a review')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(truck: widget.truck),
      ),
    );

    if (result == true) {
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.user?.id == widget.truck.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.truck.name} Reviews'),
        actions: [
          if (authProvider.user != null && authProvider.isCustomer() && !isOwner)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addReview,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: authProvider.user != null && 
          authProvider.isCustomer() && 
          !isOwner &&
          !_isLoading &&
          _error == null
          ? FloatingActionButton.extended(
              onPressed: _addReview,
              icon: const Icon(Icons.rate_review),
              label: const Text('Write Review'),
            )
          : null,
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
        message: 'Be the first to review ${widget.truck.name}!',
        actionLabel: 'Write Review',
        onAction: _addReview,
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
                    isOwner: Provider.of<AuthProvider>(context).user?.id == widget.truck.ownerId,
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

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Overall Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _stats!.averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRating(
                    rating: _stats!.averageRating,
                    size: 24,
                  ),
                  Text(
                    '${_stats!.totalReviews} reviews',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Rating Distribution
          ..._buildRatingBars(),
        ],
      ),
    );
  }

  List<Widget> _buildRatingBars() {
    return List.generate(5, (index) {
      final rating = 5 - index;
      final count = _stats!.ratingDistribution[rating] ?? 0;
      final percentage = _stats!.totalReviews > 0
          ? (count / _stats!.totalReviews * 100)
          : 0.0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text('$rating'),
            const SizedBox(width: 8),
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                count.toString(),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonLoader(
            height: 150,
            borderRadius: 12,
          ),
        );
      },
    );
  }
} 
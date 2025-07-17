import 'package:flutter/material.dart';
import '../../../models/social_post.dart';
import '../../../services/api_service.dart';
import '../../../utils/theme.dart';

class SocialAnalyticsScreen extends StatefulWidget {
  final String userId;

  const SocialAnalyticsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SocialAnalyticsScreen> createState() => _SocialAnalyticsScreenState();
}

class _SocialAnalyticsScreenState extends State<SocialAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the available getSocialAnalyticsForTruck method with userId as fallback
      final analytics = await ApiService.getSocialAnalyticsForTruck(widget.userId);
      setState(() {
        _analytics = analytics;
      });
    } catch (e) {
      // For now, just show empty state since the API method might not be implemented
      setState(() {
        _analytics = {
          'totalPosts': 0,
          'totalReach': 0,
          'totalEngagement': 0,
          'avgEngagementRate': 0.0,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analytics feature coming soon!')),
      );
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
        title: const Text('Social Analytics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnalyticsView(),
    );
  }

  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          _buildOverviewSection(),
          const SizedBox(height: 24),
          
          // Platform breakdown
          _buildPlatformSection(),
          const SizedBox(height: 24),
          
          // Top performing posts
          _buildTopPostsSection(),
          const SizedBox(height: 24),
          
          // Engagement trends
          _buildEngagementTrendsSection(),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Posts',
                '${_analytics['totalPosts'] ?? 0}',
                Icons.post_add,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Engagement',
                '${_analytics['totalEngagement'] ?? 0}',
                Icons.favorite,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg. Engagement',
                '${_analytics['avgEngagement']?.toStringAsFixed(1) ?? '0.0'}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Reach',
                '${_analytics['totalReach'] ?? 0}',
                Icons.visibility,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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

  Widget _buildPlatformSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Breakdown',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPlatformRow('Instagram', '45%', Colors.purple),
                _buildPlatformRow('Facebook', '30%', Colors.blue),
                _buildPlatformRow('Twitter', '15%', Colors.lightBlue),
                _buildPlatformRow('LinkedIn', '10%', Colors.indigo),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformRow(String platform, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(platform),
          ),
          Text(
            percentage,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performing Posts',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTopPostRow('Pizza Tuesday Special!', 'Instagram', '245 likes'),
                _buildTopPostRow('New Location Alert 🚚', 'Facebook', '189 shares'),
                _buildTopPostRow('Behind the scenes...', 'Twitter', '156 retweets'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPostRow(String title, String platform, String engagement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  platform,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            engagement,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementTrendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement Trends',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('📈 Engagement up 15% this month'),
                const SizedBox(height: 8),
                const Text('🕐 Best posting time: 12:00 PM - 2:00 PM'),
                const SizedBox(height: 8),
                const Text('📱 Top platform: Instagram'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Show detailed analytics
                  },
                  child: const Text('View Detailed Report'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 
import 'package:flutter/material.dart';
import '../../../models/social_post.dart';
import '../../../services/api_service.dart';
import '../../../utils/theme.dart';

class ContentCalendarScreen extends StatefulWidget {
  final String userId;

  const ContentCalendarScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ContentCalendarScreen> createState() => _ContentCalendarScreenState();
}

class _ContentCalendarScreenState extends State<ContentCalendarScreen> {
  final ApiService _apiService = ApiService();
  List<SocialPost> _scheduledPosts = [];
  bool _isLoading = false;
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadScheduledPosts();
  }

  Future<void> _loadScheduledPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await _apiService.getScheduledPosts(widget.userId);
      setState(() {
        _scheduledPosts = posts.map((post) => SocialPost.fromJson(post)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading scheduled posts: $e')),
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
        title: const Text('Content Calendar'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCalendarView(),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // Calendar header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheduled Posts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadScheduledPosts,
              ),
            ],
          ),
        ),
        
        // Posts list
        Expanded(
          child: _scheduledPosts.isEmpty
              ? const Center(
                  child: Text(
                    'No scheduled posts',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scheduledPosts.length,
                  itemBuilder: (context, index) {
                    final post = _scheduledPosts[index];
                    return _buildPostCard(post);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPostCard(SocialPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPlatformIcon(post.platforms.isNotEmpty ? post.platforms.first : 'general'),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  post.platforms.isNotEmpty ? post.platforms.first.toUpperCase() : 'GENERAL',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  post.scheduledTime != null
                      ? '${post.scheduledTime!.day}/${post.scheduledTime!.month}/${post.scheduledTime!.year}'
                      : 'Not scheduled',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(post.status.toUpperCase()),
                  backgroundColor: _getStatusColor(post.status),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Navigate to edit post
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // TODO: Delete post
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email;
      case 'linkedin':
        return Icons.business;
      case 'tiktok':
        return Icons.music_note;
      default:
        return Icons.share;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue.shade100;
      case 'published':
        return Colors.green.shade100;
      case 'draft':
        return Colors.grey.shade100;
      case 'failed':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
} 
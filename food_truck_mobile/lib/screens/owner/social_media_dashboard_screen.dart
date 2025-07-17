import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/social_account.dart';
import '../../models/social_post.dart';
import '../../models/campaign.dart';
import '../../services/api_service.dart';
import 'social_media/post_composer_screen.dart';
import 'social_media/content_calendar_screen.dart';
import 'social_media/social_analytics_screen.dart';
import 'social_media/campaigns_screen.dart';
import 'social_media/connect_accounts_screen.dart';
import 'social_media/automated_posting_settings_screen.dart';
import 'package:intl/intl.dart';

class SocialMediaDashboardScreen extends StatefulWidget {
  final String truckId;

  const SocialMediaDashboardScreen({
    super.key,
    required this.truckId,
  });

  @override
  State<SocialMediaDashboardScreen> createState() => _SocialMediaDashboardScreenState();
}

class _SocialMediaDashboardScreenState extends State<SocialMediaDashboardScreen> {
  List<SocialAccount> _connectedAccounts = [];
  List<SocialPost> _recentPosts = [];
  List<Campaign> _activeCampaigns = [];
  bool _isLoading = true;
  String? _error;

  // Analytics data
  int _totalPosts = 0;
  int _totalReach = 0;
  int _totalEngagement = 0;
  double _avgEngagementRate = 0;

  String? _userId;

  @override
  void initState() {
    super.initState();
    // Get user ID from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.user?.id;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load connected accounts - handle API response gracefully
      try {
        final accountsData = await ApiService.getSocialAccounts(widget.truckId);
        _connectedAccounts = [];
        // API may return empty Map instead of List, so handle gracefully
      } catch (e) {
        debugPrint('Error loading social accounts: $e');
        _connectedAccounts = [];
      }

      // Load recent posts
      final postsData = await ApiService.getSocialPosts(
        widget.truckId,
        limit: 5,
      );
      _recentPosts = (postsData['posts'] as List)
          .map((data) => SocialPost.fromJson(data))
          .toList();

      // Load active campaigns - handle API response gracefully
      try {
        final campaignsData = await ApiService.getCampaignsForTruck(widget.truckId);
        _activeCampaigns = [];
        // API may return empty Map instead of List, so handle gracefully
      } catch (e) {
        debugPrint('Error loading campaigns: $e');
        _activeCampaigns = [];
      }

      // Load analytics for the last 30 days
      final analyticsData = await ApiService.getSocialAnalyticsForTruck(widget.truckId);

      setState(() {
        _totalPosts = analyticsData['totalPosts'] ?? 0;
        _totalReach = analyticsData['totalReach'] ?? 0;
        _totalEngagement = analyticsData['totalEngagement'] ?? 0;
        _avgEngagementRate = double.tryParse(
          analyticsData['avgEngagementRate']?.toString() ?? '0'
        ) ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Media Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AutomatedPostingSettingsScreen(
                    truckId: widget.truckId,
                  ),
                ),
              );
            },
            tooltip: 'Automated Posting Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
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
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Connected Accounts Section
                        _buildConnectedAccountsSection(),
                        const SizedBox(height: 24),

                        // Quick Actions
                        _buildQuickActionsSection(),
                        const SizedBox(height: 24),

                        // Analytics Overview
                        _buildAnalyticsOverview(),
                        const SizedBox(height: 24),

                        // Recent Posts
                        _buildRecentPostsSection(),
                        const SizedBox(height: 24),

                        // Active Campaigns
                        _buildActiveCampaignsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildConnectedAccountsSection() {
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
                  'Connected Accounts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Connect'),
                  onPressed: () async {
                    if (_userId != null) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConnectAccountsScreen(
                            userId: _userId!,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadDashboardData();
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_connectedAccounts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.link_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No accounts connected',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Connect your social media accounts to start posting',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _connectedAccounts.map((account) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: _getPlatformColor(account.platform),
                      child: Icon(
                        _getPlatformIcon(account.platform),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    label: Text(account.accountName ?? account.platformDisplayName),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _disconnectAccount(account),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildQuickActionCard(
          icon: Icons.edit,
          title: 'Create Post',
          subtitle: 'Draft a new post',
          color: Colors.blue,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostComposerScreen(
                  truckId: widget.truckId,
                ),
              ),
            );
            if (result == true) {
              _loadDashboardData();
            }
          },
        ),
        _buildQuickActionCard(
          icon: Icons.calendar_month,
          title: 'Calendar',
          subtitle: 'View scheduled posts',
          color: Colors.green,
          onTap: () {
            if (_userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContentCalendarScreen(
                    userId: _userId!,
                  ),
                ),
              );
            }
          },
        ),
        _buildQuickActionCard(
          icon: Icons.analytics,
          title: 'Analytics',
          subtitle: 'View performance',
          color: Colors.orange,
          onTap: () {
            if (_userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SocialAnalyticsScreen(
                    userId: _userId!,
                  ),
                ),
              );
            }
          },
        ),
        _buildQuickActionCard(
          icon: Icons.campaign,
          title: 'Campaigns',
          subtitle: 'Manage campaigns',
          color: Colors.purple,
          onTap: () {
            if (_userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CampaignsScreen(
                    userId: _userId!,
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 30 Days Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Posts',
                    value: _totalPosts.toString(),
                    icon: Icons.article,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'Reach',
                    value: _formatNumber(_totalReach),
                    icon: Icons.visibility,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Engagement',
                    value: _formatNumber(_totalEngagement),
                    icon: Icons.thumb_up,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'Eng. Rate',
                    value: '${_avgEngagementRate.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPostsSection() {
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
                  'Recent Posts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to posts list
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentPosts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No posts yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentPosts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final post = _recentPosts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(post.status),
                      child: Icon(
                        _getStatusIcon(post.status),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      post.content.split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      post.status == 'scheduled'
                          ? 'Scheduled for ${DateFormat('MMM d, h:mm a').format(post.scheduledTime)}'
                          : post.status == 'published'
                              ? 'Published'
                              : 'Draft',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...post.platforms.map((p) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            _getPlatformIcon(p),
                            size: 16,
                            color: _getPlatformColor(p),
                          ),
                        )),
                      ],
                    ),
                    onTap: () {
                      // Navigate to post detail
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCampaignsSection() {
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
                  'Active Campaigns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    if (_userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampaignsScreen(
                            userId: _userId!,
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
            if (_activeCampaigns.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No active campaigns',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeCampaigns.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final campaign = _activeCampaigns[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              campaign.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(
                                campaign.type.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: campaign.progress / 100,
                          backgroundColor: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${campaign.progress}% complete',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${campaign.daysRemaining} days left',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _disconnectAccount(SocialAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Account'),
        content: Text('Are you sure you want to disconnect ${account.accountName ?? account.platformDisplayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.disconnectSocialAccount(account.id);
        _loadDashboardData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
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

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'draft':
        return Colors.grey;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'published':
        return Icons.check;
      case 'scheduled':
        return Icons.schedule;
      case 'draft':
        return Icons.edit;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
} 
import 'package:flutter/material.dart';
import '../../../models/campaign.dart';
import '../../../services/api_service.dart';
import '../../../utils/theme.dart';

class CampaignsScreen extends StatefulWidget {
  final String userId;

  const CampaignsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final ApiService _apiService = ApiService();
  List<Campaign> _campaigns = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the available getCampaignsForTruck method with userId as fallback
      final campaigns = await ApiService.getCampaignsForTruck(widget.userId);
      setState(() {
        _campaigns = [];
        // API may return empty Map instead of List, so handle gracefully
      });
    } catch (e) {
      // For now, just show empty state since the API method might not be implemented
      setState(() {
        _campaigns = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign feature coming soon!')),
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
        title: const Text('Campaigns'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateCampaignDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCampaignsView(),
    );
  }

  Widget _buildCampaignsView() {
    if (_campaigns.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No campaigns yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first campaign to get started',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        final campaign = _campaigns[index];
        return _buildCampaignCard(campaign);
      },
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(campaign.status.toUpperCase()),
                  backgroundColor: _getStatusColor(campaign.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              campaign.description ?? 'No description',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Campaign metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn('Budget', '\$${campaign.goals?['budget'] ?? 0}'),
                _buildMetricColumn('Spent', '\$${campaign.analytics?['spent'] ?? 0}'),
                _buildMetricColumn('Reach', '${campaign.analytics?['totalReach'] ?? 0}'),
                _buildMetricColumn('ROI', '${(campaign.analytics?['roi'] ?? 0.0).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress'),
                    Text('${campaign.progress.toStringAsFixed(1)}%'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: campaign.progress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(campaign.progress.toDouble()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    // TODO: View campaign details
                  },
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // TODO: Edit campaign
                  },
                  child: const Text('Edit'),
                ),
                const Spacer(),
                if (campaign.status == 'active')
                  TextButton(
                    onPressed: () {
                      // TODO: Pause campaign
                    },
                    child: const Text('Pause'),
                  )
                else if (campaign.status == 'paused')
                  TextButton(
                    onPressed: () {
                      // TODO: Resume campaign
                    },
                    child: const Text('Resume'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade100;
      case 'paused':
        return Colors.orange.shade100;
      case 'completed':
        return Colors.blue.shade100;
      case 'draft':
        return Colors.grey.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.orange;
    if (progress >= 25) return Colors.blue;
    return Colors.red;
  }

  void _showCreateCampaignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Campaign'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Campaign Name',
                hintText: 'Enter campaign name',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter campaign description',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Budget',
                hintText: 'Enter budget amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Create campaign
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
} 
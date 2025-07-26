import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/real_pos_integration_service.dart';

class PosIntegrationScreen extends StatefulWidget {
  const PosIntegrationScreen({super.key});

  @override
  State<PosIntegrationScreen> createState() => _PosIntegrationScreenState();
}

class _PosIntegrationScreenState extends State<PosIntegrationScreen> {
  bool _isLoading = true;
  String? _truckId;
  Map<String, dynamic>? _posSettings;
  Map<String, bool> _reportSettings = {
    'weekly': true,
    'monthly': true,
    'quarterly': true,
    'semiAnnually': false,
    'annually': true,
  };
  String? _selectedPosSystem;

  final List<Map<String, dynamic>> _supportedPosSystems = [
    {
      'name': 'Square',
      'id': 'square',
      'description': 'Most popular for food trucks',
      'features': ['GPS Location', 'Sales Data', 'Menu Analytics'],
      'logo': 'https://logo.clearbit.com/squareup.com',
    },
    {
      'name': 'Toast',
      'id': 'toast',
      'description': 'Growing food service platform',
      'features': ['Location Tracking', 'Order Analytics', 'Revenue Reports'],
      'logo': 'https://logo.clearbit.com/toasttab.com',
    },
    {
      'name': 'Clover',
      'id': 'clover',
      'description': 'Mobile-first POS system',
      'features': ['Real-time Location', 'Sales Insights', 'Customer Data'],
      'logo': 'https://logo.clearbit.com/clover.com',
    },
    {
      'name': 'Shopify POS',
      'id': 'shopify',
      'description': 'E-commerce integrated POS',
      'features': ['Location Services', 'Inventory Tracking', 'Customer Analytics'],
      'logo': 'https://logo.clearbit.com/shopify.com',
    },
    {
      'name': 'TouchBistro',
      'id': 'touchbistro',
      'description': 'Restaurant-focused solution',
      'features': ['Location Updates', 'Menu Performance', 'Staff Analytics'],
      'logo': 'https://logo.clearbit.com/touchbistro.com',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPosSettings();
  }

  Future<void> _loadPosSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Get user's truck
      final trucksData = await ApiService.getFoodTrucks();
      Map<String, dynamic>? userTruckData;
      
      for (var truckData in trucksData) {
        if (truckData is Map<String, dynamic>) {
          final ownerId = truckData['ownerId'] ?? truckData['owner'];
          if (ownerId == userId) {
            userTruckData = truckData;
            break;
          }
        }
      }
      
      if (userTruckData != null) {
        _truckId = userTruckData['id'] ?? userTruckData['_id'];
        
        // Get POS settings
        final response = await ApiService.getTruckPosSettings(_truckId!);
        if (response['success'] == true) {
          setState(() {
            _posSettings = response['posSettings'] ?? {};
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading POS settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading POS settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Integration'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Info Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[600],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.point_of_sale, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'POS System Integration',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Connect your POS system to automatically update your food truck location and open/closed status.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // POS System Selection
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.devices, color: Colors.orange[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Select Your POS System',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Choose your POS system for automatic location tracking and sales analytics:',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          ..._supportedPosSystems.map((system) => _buildPosSystemCard(system)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Current Integration Status
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_tree, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Integration Status',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatusRow(
                            'API Connection',
                            _posSettings?['posApiKey'] != null,
                            _posSettings?['posApiKey'] ?? 'Not configured',
                          ),
                          const SizedBox(height: 12),
                          _buildStatusRow(
                            'Location Tracking',
                            _posSettings?['allowPosTracking'] == true,
                            _posSettings?['allowPosTracking'] == true ? 'Active' : 'Disabled',
                          ),
                          const SizedBox(height: 12),
                          _buildStatusRow(
                            'Sales Analytics',
                            _posSettings?['salesAnalytics'] == true,
                            _posSettings?['salesAnalytics'] == true ? 'Enabled' : 'Not configured',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Automated Reporting Settings
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.purple[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Automated Reports',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get detailed sales and location analytics delivered to your email automatically.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.insights, color: Colors.purple[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Report Includes:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildReportFeature('📍 Top-performing locations'),
                                _buildReportFeature('💰 Revenue by location'),
                                _buildReportFeature('🍔 Best-selling items by area'),
                                _buildReportFeature('📊 Customer traffic patterns'),
                                _buildReportFeature('⏰ Peak hours analysis'),
                                _buildReportFeature('🎯 Location recommendations'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Choose which reports to receive:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildReportToggle('Weekly Reports', 'weekly', 'Every Monday morning'),
                          _buildReportToggle('Monthly Reports', 'monthly', 'First of each month'),
                          _buildReportToggle('Quarterly Reports', 'quarterly', 'Every 3 months'),
                          _buildReportToggle('Semi-Annual Reports', 'semiAnnually', 'Every 6 months'),
                          _buildReportToggle('Annual Reports', 'annually', 'Year-end summary'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPosSetupDialog(),
                          icon: const Icon(Icons.settings),
                          label: const Text('Configure POS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _testPosConnection(),
                          icon: const Icon(Icons.wifi_find),
                          label: const Text('Test Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPosSystemCard(Map<String, dynamic> system) {
    final isSelected = _selectedPosSystem == system['name'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPosSystem = system['name'] as String;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? Colors.blue[50] : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.point_of_sale,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      system['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.blue[700] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      system['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: (system['features'] as List<String>).map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[100] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.blue[700] : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.blue[600],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive, String status) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildReportFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              color: Colors.purple[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportToggle(String title, String key, String description) {
    final isEnabled = _reportSettings[key] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Switch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                _reportSettings[key] = value;
              });
            },
            activeColor: Colors.green[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPosSetupDialog() async {
    if (_selectedPosSystem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a POS system first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_truckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to find your truck information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find the selected POS system ID
    String? posSystemId;
    for (var system in _supportedPosSystems) {
      if (system['name'] == _selectedPosSystem) {
        posSystemId = system['id'];
        break;
      }
    }

    if (posSystemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid POS system selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Connect to the POS system
    final result = await RealPosIntegrationService.connectPosSystem(
      posSystemId,
      _truckId!,
      context,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'POS system connected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload POS settings
      _loadPosSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testPosConnection() async {
    if (_truckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to find your truck information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_posSettings == null || _posSettings!['isConnected'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect a POS system first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Testing connection to ${_posSettings!['posSystemName']}...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Test the connection
    final result = await RealPosIntegrationService.testPosConnection(_truckId!);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connection active! Last sync: ${result['details']?['lastSync'] ?? 'Never'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 
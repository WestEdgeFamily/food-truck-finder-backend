import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PosIntegrationScreen extends StatefulWidget {
  const PosIntegrationScreen({super.key});

  @override
  State<PosIntegrationScreen> createState() => _PosIntegrationScreenState();
}

class _PosIntegrationScreenState extends State<PosIntegrationScreen> {
  bool _isLoading = true;
  String? _truckId;
  Map<String, dynamic>? _posSettings;
  List<dynamic> _childAccounts = [];

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
            _childAccounts = _posSettings?['childAccounts'] ?? [];
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

  Future<void> _showAddChildAccountDialog() async {
    final nameController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add POS Terminal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Terminal Name',
                hintText: 'e.g. Main Register, Kitchen POS',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create a new API key for your POS terminal to update location and status.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a terminal name')),
                );
                return;
              }
              
              Navigator.pop(context);
              await _createChildAccount(nameController.text.trim());
            },
            child: const Text('Add Terminal'),
          ),
        ],
      ),
    );
  }

  Future<void> _createChildAccount(String name) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) return;
      
      final response = await ApiService.createPosChildAccount(
        userId,
        {
          'name': name,
          'permissions': ['location_update', 'status_update'],
        },
      );
      
      if (response['success'] == true) {
        await _loadPosSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('POS terminal added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating child account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding terminal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deactivateChildAccount(String childId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Terminal?'),
        content: const Text('This terminal will no longer be able to update your location or status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) return;
      
      final response = await ApiService.deactivatePosChildAccount(childId, userId);
      
      if (response['success'] == true) {
        await _loadPosSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terminal deactivated'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error deactivating child account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deactivating terminal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
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
                  // Info Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'POS System Integration',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect your POS system to automatically update your food truck location and open/closed status.',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Parent Account Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parent Account',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildApiKeyRow(
                            'Main API Key',
                            _posSettings?['posApiKey'] ?? 'Not available',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _posSettings?['allowPosTracking'] == true 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                                color: _posSettings?['allowPosTracking'] == true 
                                    ? Colors.green 
                                    : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _posSettings?['allowPosTracking'] == true 
                                    ? 'POS tracking enabled' 
                                    : 'POS tracking disabled',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Child Accounts
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'POS Terminals',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _showAddChildAccountDialog,
                                icon: const Icon(Icons.add),
                                tooltip: 'Add Terminal',
                              ),
                            ],
                          ),
                          if (_childAccounts.isEmpty) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.point_of_sale, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No POS terminals added yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            ..._childAccounts.map((account) => _buildChildAccountTile(account)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Integration Guide
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Integration Guide',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGuideStep('1', 'Create a POS terminal above'),
                          _buildGuideStep('2', 'Copy the API key'),
                          _buildGuideStep('3', 'Configure your POS system with the API endpoint'),
                          _buildGuideStep('4', 'Your location will update automatically'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChildAccountDialog,
        tooltip: 'Add POS Terminal',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildApiKeyRow(String label, String apiKey) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                apiKey.length > 30 ? '${apiKey.substring(0, 30)}...' : apiKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _copyToClipboard(apiKey),
          icon: const Icon(Icons.copy, size: 20),
          tooltip: 'Copy',
        ),
      ],
    );
  }

  Widget _buildChildAccountTile(Map<String, dynamic> account) {
    final isActive = account['isActive'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? null : Colors.grey[100],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account['name'] ?? 'Unnamed Terminal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.green[900] : Colors.red[900],
                      ),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deactivateChildAccount(account['id']),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      iconSize: 20,
                      tooltip: 'Deactivate',
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildApiKeyRow('API Key', account['apiKey'] ?? ''),
          const SizedBox(height: 4),
          Text(
            'Created: ${_formatDate(account['createdAt'])}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
} 
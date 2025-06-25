import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PosManagementScreen extends StatefulWidget {
  const PosManagementScreen({super.key});

  @override
  State<PosManagementScreen> createState() => _PosManagementScreenState();
}

class _PosManagementScreenState extends State<PosManagementScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _posSettings;
  List<dynamic> _childAccounts = [];
  final _childAccountNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosSettings();
  }

  @override
  void dispose() {
    _childAccountNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPosSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final businessName = authProvider.user?.businessName;
      
      if (userId == null) return;
      
      // First, find the user's truck to get the correct owner ID
      final trucksResponse = await ApiService.get('/trucks');
      final List<dynamic> trucks = trucksResponse is List 
          ? trucksResponse 
          : (trucksResponse is Map && trucksResponse.containsKey('trucks') 
              ? trucksResponse['trucks'] 
              : <dynamic>[]);
      
      // Find truck by owner ID or business name
      Map<String, dynamic>? userTruck;
      for (var truck in trucks) {
        if (truck is Map<String, dynamic>) {
          final ownerId = truck['ownerId'] ?? truck['owner'];
          final truckBusinessName = truck['businessName'] ?? truck['name'];
          
          if (ownerId == userId || 
              (businessName != null && truckBusinessName == businessName)) {
            userTruck = truck;
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

      // Load POS settings using truck ID
      final posResponse = await ApiService.get('/trucks/$truckId/pos-settings');
      
      if (posResponse is Map<String, dynamic>) {
        final posSettings = posResponse['posSettings'] ?? posResponse;
        if (posSettings is Map<String, dynamic>) {
          _posSettings = Map<String, dynamic>.from(posSettings);
        }
      } else if (posResponse is Map<String, dynamic>) {
        _posSettings = Map<String, dynamic>.from(posResponse);
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading POS settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading POS settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createChildAccount() async {
    if (_childAccountNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the POS account')),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final businessName = authProvider.user?.businessName;
      
      if (userId == null) return;
      
      // Find the user's truck to get the correct owner ID
      final trucksResponse = await ApiService.get('/trucks');
      final List<dynamic> trucks = trucksResponse is List 
          ? trucksResponse 
          : (trucksResponse is Map && trucksResponse.containsKey('trucks') 
              ? trucksResponse['trucks'] 
              : <dynamic>[]);
      
      Map<String, dynamic>? userTruck;
      for (var truck in trucks) {
        if (truck is Map<String, dynamic>) {
          if (truck['ownerId'] == userId || 
              (businessName != null && truck['businessName'] == businessName)) {
            userTruck = truck;
            break;
          }
        }
      }
      
      if (userTruck == null) {
        throw Exception('No food truck found for this account');
      }
      
      final truckOwnerId = userTruck['ownerId'];
      
      final response = await ApiService.post('/pos/child-account', {
        'parentOwnerId': truckOwnerId,
        'childAccountName': _childAccountNameController.text.trim(),
        'permissions': ['location_update', 'status_update']
      });

      if (response['success']) {
        _childAccountNameController.clear();
        await _loadPosSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('POS account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating POS account: $e')),
      );
    }
  }

  void _showCreateChildAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add POS Terminal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this POS terminal:'),
            const SizedBox(height: 16),
            TextField(
              controller: _childAccountNameController,
              decoration: const InputDecoration(
                labelText: 'Terminal Name',
                hintText: 'e.g., Main Register, Mobile POS',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _childAccountNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createChildAccount();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('POS Integration'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Integration'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'POS Integration',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect your Point of Sale (POS) system to automatically update your food truck\'s location and status. Create child accounts for your POS terminals.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Parent account section
            Text(
              'Parent Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Main Account',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Parent account for ${Provider.of<AuthProvider>(context).user?.businessName ?? "your business"}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showApiKeyDialog(
                            'Parent Account',
                            _posSettings?['posApiKey'] ?? 'No API key',
                          ),
                          icon: const Icon(Icons.key),
                          tooltip: 'View API Key',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Child accounts section
            Row(
              children: [
                Expanded(
                  child: Text(
                    'POS Terminal Accounts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showCreateChildAccountDialog,
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: 'Add POS Terminal',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_childAccounts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.point_of_sale,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No POS terminals connected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create child accounts for your POS terminals to enable automatic location tracking',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showCreateChildAccountDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Terminal'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._childAccounts.map((account) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: account['isActive'] 
                              ? Colors.green[100] 
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.point_of_sale,
                          color: account['isActive'] 
                              ? Colors.green[700] 
                              : Colors.red[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              account['isActive'] ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: account['isActive'] 
                                    ? Colors.green[700] 
                                    : Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showApiKeyDialog(
                          account['name'],
                          account['apiKey'],
                        ),
                        icon: const Icon(Icons.key),
                        tooltip: 'View API Key',
                      ),
                      if (account['isActive'])
                        IconButton(
                          onPressed: () => _deactivateChildAccount(
                            account['id'],
                            account['name'],
                          ),
                          icon: const Icon(Icons.block),
                          color: Colors.red,
                          tooltip: 'Deactivate',
                        ),
                    ],
                  ),
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog(String accountName, String apiKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$accountName API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use this API key in your POS system to enable location tracking:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                apiKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Integration endpoint:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const SelectableText(
                'POST /api/pos/location-update\n\nBody:\n{\n  "apiKey": "your_api_key",\n  "latitude": 40.7589,\n  "longitude": -111.8883,\n  "address": "123 Main St",\n  "isOpen": true\n}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _copyApiKey(apiKey),
            child: const Text('Copy API Key'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _copyApiKey(String apiKey) {
    Clipboard.setData(ClipboardData(text: apiKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deactivateChildAccount(String childId, String childName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate POS Account'),
        content: Text('Are you sure you want to deactivate "$childName"? This will prevent it from updating your truck\'s location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.put('/pos/child-account/$childId/deactivate', {
        'ownerId': authProvider.user?.id,
      });

      await _loadPosSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$childName deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deactivating account: $e')),
      );
    }
  }
} 
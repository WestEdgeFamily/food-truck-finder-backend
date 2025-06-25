import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_truck_provider.dart';
import '../../services/api_service.dart';
import '../../models/food_truck.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<MenuItem> _menuItems = [];
  String? _currentTruckId;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAndLoadMenu();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoadMenu() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Get all trucks from API directly
      final trucksData = await ApiService.getFoodTrucks();
      
      // Find the truck owned by the current user
      Map<String, dynamic>? userTruckData;
      for (var truckData in trucksData) {
        if (truckData is Map<String, dynamic>) {
          // Check both ownerId and owner fields
          final ownerId = truckData['ownerId'] ?? truckData['owner'];
          if (ownerId == userId) {
            userTruckData = truckData;
            break;
          }
        }
      }
      
      if (userTruckData != null) {
        // Use the custom id field from the backend
        final truckId = userTruckData['id'] ?? userTruckData['_id'];
        if (truckId != null) {
          _currentTruckId = truckId.toString();
          debugPrint('🍽️ Found user truck with ID: $_currentTruckId');
          
          // Load menu items
          final menuItems = await ApiService.getMenu(_currentTruckId!);
          setState(() {
            _menuItems = menuItems.map((item) => MenuItem.fromJson(item)).toList();
          });
          debugPrint('🍽️ Loaded ${_menuItems.length} menu items');
        } else {
          throw Exception('Truck ID not found');
        }
      } else {
        // No truck found for user - create one
        debugPrint('🚚 No truck found for user, creating new truck...');
        
        final newTruckData = {
          'name': authProvider.user?.businessName ?? 'My Food Truck',
          'businessName': authProvider.user?.businessName ?? 'My Food Truck',
          'description': 'Delicious food on wheels!',
          'ownerId': userId,
          'cuisine': 'American',
          'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
          'email': authProvider.user?.email ?? '',
          'website': '',
          'location': {
            'latitude': 40.7128,
            'longitude': -74.0060,
            'address': 'New York, NY'
          },
          'hours': 'Hours to be set by owner',
          'isOpen': false,
          'isActive': true,
          'menu': [],
          'schedule': {
            'monday': {'open': '09:00', 'close': '17:00', 'isOpen': true},
            'tuesday': {'open': '09:00', 'close': '17:00', 'isOpen': true},
            'wednesday': {'open': '09:00', 'close': '17:00', 'isOpen': true},
            'thursday': {'open': '09:00', 'close': '17:00', 'isOpen': true},
            'friday': {'open': '09:00', 'close': '17:00', 'isOpen': true},
            'saturday': {'open': '10:00', 'close': '16:00', 'isOpen': true},
            'sunday': {'open': '10:00', 'close': '16:00', 'isOpen': false}
          },
          'rating': 0,
          'reviewCount': 0,
          'posSettings': {
            'allowPosTracking': true,
            'childAccounts': []
          }
        };
        
        final result = await ApiService.createFoodTruck(newTruckData);
        if (result['success'] == true && result['truck'] != null) {
          final createdTruck = result['truck'];
          _currentTruckId = (createdTruck['id'] ?? createdTruck['_id']).toString();
          debugPrint('✅ Created new truck with ID: $_currentTruckId');
          setState(() {
            _menuItems = [];
          });
        } else {
          throw Exception('Failed to create truck');
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing menu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading menu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMenuToBackend() async {
    if (_currentTruckId == null || _isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Convert menu items to JSON
      final menuJson = _menuItems.map((item) => item.toJson()).toList();
      
      // Save to backend
      await ApiService.saveMenu(_currentTruckId!, menuJson);
      
      debugPrint('✅ Menu saved to backend successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving menu: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save menu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showAddItemDialog() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _categoryController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addMenuItem,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addMenuItem() async {
    if (_nameController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name and price')),
      );
      return;
    }

    final newItem = MenuItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      category: _categoryController.text.trim().isEmpty ? 'Other' : _categoryController.text.trim(),
    );

    setState(() {
      _menuItems.add(newItem);
    });

    Navigator.pop(context);
    
    // Auto-save to backend
    await _saveMenuToBackend();
  }

  void _deleteMenuItem(String itemId) async {
    setState(() {
      _menuItems.removeWhere((item) => item.id == itemId);
    });
    
    // Auto-save to backend
    await _saveMenuToBackend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSaving ? 'Menu Management (Saving...)' : 'Menu Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else ...[
            IconButton(
              onPressed: _saveMenuToBackend,
              icon: const Icon(Icons.save),
              tooltip: 'Save Menu',
            ),
            IconButton(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add),
              tooltip: 'Add Item',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No menu items yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first menu item',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.description.isNotEmpty)
                              Text(item.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.category ?? 'Other',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _deleteMenuItem(item.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 
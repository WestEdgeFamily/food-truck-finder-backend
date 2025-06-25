import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_truck_provider.dart';
import '../../services/api_service.dart';
import '../../models/food_truck.dart';

class TruckManagementScreen extends StatefulWidget {
  const TruckManagementScreen({super.key});

  @override
  State<TruckManagementScreen> createState() => _TruckManagementScreenState();
}

class _TruckManagementScreenState extends State<TruckManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  
  FoodTruck? _currentTruck;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _selectedImageUrl;
  final ImagePicker _picker = ImagePicker();

  // Sample cover photo URLs for demo
  final List<String> _sampleCoverPhotos = [
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=800&h=600&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _loadTruckData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();

    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _deleteTestTrucks() async {
    setState(() => _isLoading = true);
    
    try {
      final trucks = await ApiService.getFoodTrucks();
      final testTruckNames = ['test truck', 'test truck full', 'updated test truck'];
      int deletedCount = 0;
      
      for (var truck in trucks) {
        if (truck is Map<String, dynamic>) {
          final name = (truck['name'] ?? '').toString().toLowerCase();
          final businessName = (truck['businessName'] ?? '').toString().toLowerCase();
          final id = truck['id'] ?? truck['_id'];
          
          if (testTruckNames.any((test) => 
              name.contains(test.toLowerCase()) || 
              businessName.contains(test.toLowerCase()))) {
            await ApiService.deleteFoodTruck(id.toString());
            deletedCount++;
          }
        }
      }
      
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted $deletedCount test truck(s)'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the truck list if needed
      setState(() {});
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting test trucks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadTruckData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
      
      // Load all trucks and find the one owned by current user
      await foodTruckProvider.loadFoodTrucks();
      
      // First try to find existing truck by ownerId
      FoodTruck? userTruck = foodTruckProvider.allFoodTrucks.cast<FoodTruck?>().firstWhere(
        (truck) => truck?.ownerId == authProvider.user?.id,
        orElse: () => null,
      );
      
      // If no truck found, it might have been auto-created during registration
      // Try to find by business name match
      if (userTruck == null && authProvider.user?.businessName != null) {
        userTruck = foodTruckProvider.allFoodTrucks.cast<FoodTruck?>().firstWhere(
          (truck) => truck?.businessName == authProvider.user?.businessName,
          orElse: () => null,
        );
      }
      
      // If still no truck, create a placeholder
      if (userTruck == null) {
        userTruck = FoodTruck(
          id: '',
          name: authProvider.user?.businessName ?? 'My Food Truck',
          businessName: authProvider.user?.businessName ?? 'My Food Truck',
          description: 'Welcome to our food truck! We serve delicious food.',
          ownerId: authProvider.user?.id ?? '',
        );
      }
      
      setState(() {
        _currentTruck = userTruck;
        _nameController.text = userTruck!.name;
        _descriptionController.text = userTruck.description;
  
        _emailController.text = userTruck.email ?? authProvider.user?.email ?? '';
        _websiteController.text = userTruck.website ?? '';
        _selectedImageUrl = userTruck.image;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading truck data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCoverPhoto(String imageUrl) async {
    if (_currentTruck == null) return;
    
    setState(() => _isUpdating = true);
    
    try {
      final response = await ApiService.updateTruckCoverPhoto(_currentTruck!.id, imageUrl);
      
      if (response['success'] == true) {
        setState(() {
          _selectedImageUrl = imageUrl;
          _currentTruck = _currentTruck!.copyWith(image: imageUrl);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the food truck provider
        final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
        await foodTruckProvider.loadFoodTrucks();
      } else {
        throw Exception('Failed to update cover photo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating cover photo: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showCoverPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Cover Photo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Sample Photos'),
              subtitle: const Text('Select from pre-made food truck photos'),
              onTap: () {
                Navigator.pop(context);
                _showSamplePhotos();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to take a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from your photo gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            
            if (_selectedImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSamplePhotos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Sample Photo'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _sampleCoverPhotos.length,
            itemBuilder: (context, index) {
              final photoUrl = _sampleCoverPhotos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _updateCoverPhoto(photoUrl);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedImageUrl == photoUrl 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey[300]!,
                      width: _selectedImageUrl == photoUrl ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        // For now, we'll use a placeholder URL since we don't have image upload backend
        // In a real app, you would upload the image to a server and get back a URL
        final String placeholderUrl = 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800&h=600&fit=crop';
        
        await _updateCoverPhoto(placeholderUrl);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo selected! In a full implementation, this would upload your actual photo.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _removePhoto() async {
    await _updateCoverPhoto('');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTestAccount = authProvider.user?.email?.toLowerCase().contains('test') ?? false;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Food Truck'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Food Truck'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Photo Section
              Text(
                'Cover Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              GestureDetector(
                onTap: _isUpdating ? null : _showCoverPhotoOptions,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_selectedImageUrl != null)
                          CachedNetworkImage(
                            imageUrl: _selectedImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Failed to load image'),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            color: Colors.grey[200],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to add cover photo'),
                              ],
                            ),
                          ),
                        
                        if (_isUpdating)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        
                        if (!_isUpdating)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Basic Information Section
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Truck Name',
                  prefixIcon: Icon(Icons.local_shipping),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your food truck name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Contact Information Section
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              

              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (Optional)',
                  prefixIcon: Icon(Icons.web),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _saveTruckData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isUpdating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Saving...'),
                          ],
                        )
                      : const Text('Save Changes'),
                ),
              ),

              if (isTestAccount) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _deleteTestTrucks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Deleting...'),
                            ],
                          )
                        : const Text('Delete Test Trucks'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTruckData() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isUpdating = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check if user is logged in and has an ID
      if (authProvider.user?.id == null) {
        throw Exception('User not logged in or missing user ID. Please log in again.');
      }
      
      debugPrint('🔍 User ID for truck creation: ${authProvider.user?.id}');
      debugPrint('🔍 User role: ${authProvider.user?.role}');
      
      final truckData = {
        'name': _nameController.text.trim(),
        'businessName': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'image': _selectedImageUrl ?? 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        'ownerId': authProvider.user?.id,
        'cuisine': 'American', // Default cuisine
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
      
      if (_currentTruck?.id != null && _currentTruck!.id.isNotEmpty) {
        // Update existing truck - use the backend ID
        final trucksResponse = await ApiService.getFoodTrucks();
        String? backendId = _currentTruck!.id;
        
        // Find the backend ID for this truck
        for (var truck in trucksResponse) {
          if (truck is Map<String, dynamic>) {
            if (truck['id'] == _currentTruck!.id || truck['_id'] == _currentTruck!.id) {
              backendId = truck['id'] ?? truck['_id'] ?? _currentTruck!.id;
              break;
            }
          }
        }
        
        await ApiService.put('/trucks/$backendId', truckData);
      } else {
        // Create new truck using the dedicated method
        final response = await ApiService.createFoodTruck(truckData);
        if (response['success'] && response['truck'] != null) {
          setState(() {
            _currentTruck = FoodTruck.fromJson(response['truck']);
          });
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food truck information saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload truck data to get latest info
      await _loadTruckData();
      
      // Reload the food truck provider
      final foodTruckProvider = Provider.of<FoodTruckProvider>(context, listen: false);
      await foodTruckProvider.loadFoodTrucks();
      
    } catch (e) {
      debugPrint('❌ Error saving truck data: $e');
      String errorMessage = 'Error saving truck data';
      
      if (e.toString().contains('User not logged in')) {
        errorMessage = 'Please log in again to save truck data';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again with complete information.';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }
} 
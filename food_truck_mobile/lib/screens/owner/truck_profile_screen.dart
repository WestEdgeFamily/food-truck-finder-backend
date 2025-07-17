import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/image_picker_widget.dart';

class TruckProfileScreen extends StatefulWidget {
  const TruckProfileScreen({super.key});

  @override
  State<TruckProfileScreen> createState() => _TruckProfileScreenState();
}

class _TruckProfileScreenState extends State<TruckProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentTruckId;
  String? _currentImageUrl;
  String? _currentCoverImageUrl;
  File? _newCoverImage;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTruckProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cuisineController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadTruckProfile() async {
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
        setState(() {
          _currentTruckId = userTruckData!['id'] ?? userTruckData['_id'];
          _nameController.text = userTruckData['name'] ?? '';
          _descriptionController.text = userTruckData['description'] ?? '';
          _cuisineController.text = userTruckData['cuisine'] ?? '';
          _emailController.text = userTruckData['email'] ?? '';
          _websiteController.text = userTruckData['website'] ?? '';
          _currentImageUrl = userTruckData['image'];
          _currentCoverImageUrl = userTruckData['coverImage'];
        });
      }
    } catch (e) {
      debugPrint('Error loading truck profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_currentTruckId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'cuisine': _cuisineController.text,
        'email': _emailController.text,
        'website': _websiteController.text,
      };
      
      // If we have a new cover image, convert to base64
      if (_newCoverImage != null) {
        try {
          final bytes = await _newCoverImage!.readAsBytes();
          final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          updateData['coverImage'] = base64Image;
        } catch (e) {
          debugPrint('Error encoding cover image: $e');
        }
      }
      
      final response = await ApiService.updateFoodTruck(_currentTruckId!, updateData);
      
      if (response['success'] == true) {
        // Update local state with saved cover image
        if (_newCoverImage != null && updateData['coverImage'] != null) {
          setState(() {
            _currentCoverImageUrl = updateData['coverImage'];
            _newCoverImage = null; // Clear the temporary file
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload to get fresh data
        await _loadTruckProfile();
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _newCoverImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truck Profile'),
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
                  // Cover Image Section
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            // Cover image container
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                image: _newCoverImage != null
                                    ? DecorationImage(
                                        image: FileImage(_newCoverImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : _currentCoverImageUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(_currentCoverImageUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: _newCoverImage == null && _currentCoverImageUrl == null
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image, size: 48, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('No cover image', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  : null,
                            ),
                            // Upload button
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: ElevatedButton.icon(
                                onPressed: _pickCoverImage,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Change Cover'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Cover Image',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Profile Image
                  Center(
                    child: ImagePickerWidget(
                      initialImageUrl: _currentImageUrl,
                      onImageSelected: (imageUrl) async {
                        if (_currentTruckId != null) {
                          try {
                            await ApiService.updateFoodTruck(_currentTruckId!, {
                              'image': imageUrl,
                            });
                            setState(() {
                              _currentImageUrl = imageUrl;
                            });
                          } catch (e) {
                            debugPrint('Error updating image: $e');
                          }
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Form fields
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Truck Name',
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
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cuisineController,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
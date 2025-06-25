import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/location_monitoring_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationBasedNotifications = true;
  bool _favoritesTruckNearby = true;
  double _notificationRadius = 20.0; // miles
  bool _testingBackend = false;
  Map<String, dynamic>? _testResults;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationBasedNotifications = prefs.getBool('location_notifications') ?? true;
      _favoritesTruckNearby = prefs.getBool('favorites_nearby') ?? true;
      _notificationRadius = prefs.getDouble('notification_radius') ?? 20.0;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  Future<void> _testBackendConnectivity() async {
    setState(() {
      _testingBackend = true;
      _testResults = null;
    });

    try {
      final results = await ApiService.testBackendConnectivity();
      setState(() {
        _testResults = results;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'error': 'Failed to run connectivity test: $e'
        };
      });
    } finally {
      setState(() {
        _testingBackend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // DEBUG SECTION - TEMPORARY
              Card(
                color: Colors.yellow[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEBUG INFO (Temporary)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('User ID: ${authProvider.user?.id ?? 'NULL'}'),
                      Text('User Email: ${authProvider.user?.email ?? 'NULL'}'),
                      Text('User Role: ${authProvider.user?.role ?? 'NULL'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Account Section
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Current Email Display
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Address'),
                  subtitle: Text(authProvider.user?.email ?? 'Not set'),
                  trailing: TextButton(
                    onPressed: () => _showChangeEmailDialog(),
                    child: const Text('Change'),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Change Password
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Password'),
                  subtitle: const Text('••••••••'),
                  trailing: TextButton(
                    onPressed: () => _showChangePasswordDialog(),
                    child: const Text('Change'),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Notifications Section
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive notifications about nearby food trucks'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSetting('notifications_enabled', value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Location Updates'),
                      subtitle: const Text('Get notified when favorite trucks move'),
                      value: _locationBasedNotifications,
                      onChanged: (value) {
                        setState(() {
                          _locationBasedNotifications = value;
                        });
                        _saveSetting('location_notifications', value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Favorite Trucks Nearby'),
                      subtitle: const Text('Alert when favorite trucks are in your area'),
                      value: _favoritesTruckNearby,
                      onChanged: (value) {
                        setState(() {
                          _favoritesTruckNearby = value;
                        });
                        _saveSetting('favorites_nearby', value);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Notification Radius'),
                      subtitle: Text('${_notificationRadius.round()} miles'),
                      trailing: SizedBox(
                        width: 150,
                        child: Slider(
                          value: _notificationRadius,
                          min: 1.0,
                          max: 50.0,
                          divisions: 49,
                          label: '${_notificationRadius.round()} miles',
                          onChanged: (value) {
                            setState(() {
                              _notificationRadius = value;
                            });
                            _saveSetting('notification_radius', value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Privacy Section
              Text(
                'Privacy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Show privacy policy
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Show terms of service
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangeEmailDialog() {
    final currentEmailController = TextEditingController();
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Current Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'New Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newEmailController.text.isNotEmpty && 
                  passwordController.text.isNotEmpty) {
                Navigator.of(context).pop();
                
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Processing email change request...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                try {
                  // FIX FOR BUG #7 - Actually call the API
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  if (authProvider.user != null) {
                    final response = await ApiService.changeEmail(
                      authProvider.user!.id,
                      newEmailController.text,
                      passwordController.text,
                    );
                    
                    // If successful, update the user's email immediately in the UI
                    if (response['success'] == true) {
                      await authProvider.updateUserEmail(newEmailController.text);
                    }
                    
                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Email changed successfully to ${newEmailController.text}'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Show error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to change email: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Change Email'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showRequirements = false;
    String passwordRequirements = '';
    
    // Load password requirements
    ApiService.getPasswordRequirements().then((response) {
      if (response['success'] == true && response['requirements'] != null) {
        passwordRequirements = response['requirements']['description'] ?? 
          'Password must be at least 8 characters long and contain uppercase, lowercase, numbers, and special characters.';
      }
    });
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  onTap: () {
                    setState(() {
                      showRequirements = true;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                
                // Password requirements
                if (showRequirements && passwordRequirements.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, 
                                 color: Colors.blue.shade700, size: 16),
                            const SizedBox(width: 8),
                            Text('Password Requirements:', 
                                 style: TextStyle(
                                   fontWeight: FontWeight.bold,
                                   color: Colors.blue.shade700,
                                   fontSize: 14,
                                 )),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          passwordRequirements,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text.isNotEmpty && 
                  newPasswordController.text == confirmPasswordController.text &&
                  currentPasswordController.text.isNotEmpty) {
                Navigator.of(context).pop();
                
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Changing password...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                try {
                  // FIX FOR PASSWORD PERSISTENCE ISSUE - Actually call the API
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  if (authProvider.user != null) {
                    await ApiService.changePassword(
                      authProvider.user!.id,
                      currentPasswordController.text,
                      newPasswordController.text,
                    );
                    
                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password changed successfully'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Show error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to change password: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match or fields are empty'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
        ),
      ),
    );
  }
} 
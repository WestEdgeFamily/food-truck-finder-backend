import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/location_monitoring_provider.dart';
import '../../providers/favorites_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Enable Notifications',
            'Receive push notifications from the app',
            Icons.notifications,
            _notificationsEnabled,
            (value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notifications_enabled', value);
            },
          ),
          _buildSwitchTile(
            'Location-Based Notifications',
            'Get notified when food trucks are nearby',
            Icons.location_on,
            _locationBasedNotifications,
            (value) {
              setState(() => _locationBasedNotifications = value);
              _saveSetting('location_notifications', value);
            },
            enabled: _notificationsEnabled,
          ),
          _buildSwitchTile(
            'Favorite Trucks Nearby',
            'Get notified when your favorite trucks are near you',
            Icons.favorite,
            _favoritesTruckNearby,
            (value) {
              setState(() => _favoritesTruckNearby = value);
              _saveSetting('favorites_nearby', value);
            },
            enabled: _notificationsEnabled && _locationBasedNotifications,
          ),

          // Notification Radius
          if (_notificationsEnabled && _locationBasedNotifications) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.radar,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Notification Radius',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get notified when food trucks are within ${_notificationRadius.round()} miles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _notificationRadius,
                      min: 1.0,
                      max: 50.0,
                      divisions: 49,
                      label: '${_notificationRadius.round()} miles',
                      onChanged: (value) {
                        setState(() => _notificationRadius = value);
                      },
                      onChangeEnd: (value) {
                        _saveSetting('notification_radius', value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Location Monitoring Status
          _buildSectionHeader('Location Monitoring'),
          Consumer3<LocationMonitoringProvider, LocationProvider, FavoritesProvider>(
            builder: (context, locationMonitoring, locationProvider, favoritesProvider, child) {
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        locationMonitoring.isMonitoring ? Icons.location_on : Icons.location_off,
                        color: locationMonitoring.isMonitoring 
                            ? Colors.green 
                            : Colors.grey,
                      ),
                      title: Text(
                        locationMonitoring.isMonitoring 
                            ? 'Location monitoring active' 
                            : 'Location monitoring inactive',
                      ),
                      subtitle: locationMonitoring.getLastCheckText() != null
                          ? Text('Last check: ${locationMonitoring.getLastCheckText()}')
                          : const Text('No recent checks'),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (authProvider.user?.id != null) {
                              await locationMonitoring.checkNowForNearbyTrucks(
                                locationProvider: locationProvider,
                                favoritesProvider: favoritesProvider,
                                userId: authProvider.user!.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Checked for nearby favorite trucks'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check Now'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildInfoTile(
            'App Version',
            '1.4.0 (Build 4)',
            Icons.info,
          ),

          const SizedBox(height: 24),

          // User ID Section
          _buildSectionHeader('Debug Info'),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final userId = authProvider.user?.id ?? 'Not logged in';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.perm_identity,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('User ID'),
                  subtitle: Text(
                    userId,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        secondary: Icon(
          icon,
          color: enabled ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
} 
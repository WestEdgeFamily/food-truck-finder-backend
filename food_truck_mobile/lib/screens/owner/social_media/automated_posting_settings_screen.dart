import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/oauth_service.dart';
import '../../../services/automated_posting_service.dart';
import '../../../utils/theme.dart';

class AutomatedPostingSettingsScreen extends StatefulWidget {
  final String truckId;
  
  const AutomatedPostingSettingsScreen({
    super.key,
    required this.truckId,
  });

  @override
  State<AutomatedPostingSettingsScreen> createState() => _AutomatedPostingSettingsScreenState();
}

class _AutomatedPostingSettingsScreenState extends State<AutomatedPostingSettingsScreen> {
  static const _storage = FlutterSecureStorage();
  
  bool _isEnabled = false;
  bool _includeSpecials = true;
  bool _includeLocation = true;
  bool _includeHashtags = true;
  int _postTimeOffset = 0; // Minutes before/after opening
  
  final List<Map<String, dynamic>> _connectedPlatforms = [];
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadConnectedAccounts();
  }
  
  Future<void> _loadSettings() async {
    try {
      final enabled = await _storage.read(key: 'automated_posting_enabled_${widget.truckId}');
      final includeSpecials = await _storage.read(key: 'automated_posting_specials_${widget.truckId}');
      final includeLocation = await _storage.read(key: 'automated_posting_location_${widget.truckId}');
      final includeHashtags = await _storage.read(key: 'automated_posting_hashtags_${widget.truckId}');
      final postTimeOffset = await _storage.read(key: 'automated_posting_offset_${widget.truckId}');
      
      setState(() {
        _isEnabled = enabled == 'true';
        _includeSpecials = includeSpecials != 'false';
        _includeLocation = includeLocation != 'false';
        _includeHashtags = includeHashtags != 'false';
        _postTimeOffset = int.tryParse(postTimeOffset ?? '0') ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      await _storage.write(key: 'automated_posting_enabled_${widget.truckId}', value: _isEnabled.toString());
      await _storage.write(key: 'automated_posting_specials_${widget.truckId}', value: _includeSpecials.toString());
      await _storage.write(key: 'automated_posting_location_${widget.truckId}', value: _includeLocation.toString());
      await _storage.write(key: 'automated_posting_hashtags_${widget.truckId}', value: _includeHashtags.toString());
      await _storage.write(key: 'automated_posting_offset_${widget.truckId}', value: _postTimeOffset.toString());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _loadConnectedAccounts() async {
    try {
      final accounts = await OAuthService.getAllStoredAccounts();
      setState(() {
        _connectedPlatforms.clear();
        for (final account in accounts) {
          _connectedPlatforms.add({
            'platform': account['platform'],
            'connected': true,
            'userInfo': account['user_info'],
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading connected accounts: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Posting Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Toggle
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Enable Automated Posting',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Automatically post to social media when your truck opens',
                ),
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
                secondary: Icon(
                  Icons.campaign,
                  color: _isEnabled ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Connected Accounts
            Text(
              'Connected Accounts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_connectedPlatforms.isEmpty)
              Card(
                color: Colors.orange.shade50,
                child: const ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('No accounts connected'),
                  subtitle: Text('Connect social media accounts to enable automated posting'),
                ),
              )
            else
              ..._connectedPlatforms.map((platform) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getPlatformIcon(platform['platform']),
                    color: _getPlatformColor(platform['platform']),
                  ),
                  title: Text(_capitalize(platform['platform'])),
                  subtitle: Text(
                    platform['userInfo']?['name'] ?? 
                    platform['userInfo']?['username'] ?? 
                    'Connected',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              )),
            
            const SizedBox(height: 24),
            
            // Post Content Settings
            Text(
              'Post Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Include Today\'s Specials'),
                    subtitle: const Text('Add featured menu items to the post'),
                    value: _includeSpecials,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _includeSpecials = value;
                      });
                    } : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Include Location'),
                    subtitle: const Text('Add your current location to the post'),
                    value: _includeLocation,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _includeLocation = value;
                      });
                    } : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Include Hashtags'),
                    subtitle: const Text('Add relevant hashtags for better reach'),
                    value: _includeHashtags,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _includeHashtags = value;
                      });
                    } : null,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Timing Settings
            Text(
              'Post Timing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'When to post relative to opening time:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _postTimeOffset.toDouble(),
                            min: -30,
                            max: 30,
                            divisions: 12,
                            label: _getTimingLabel(),
                            onChanged: _isEnabled ? (value) {
                              setState(() {
                                _postTimeOffset = value.round();
                              });
                            } : null,
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: Text(
                        _getTimingLabel(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isEnabled ? AppTheme.primaryColor : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Preview Section
            Text(
              'Post Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _generatePreviewMessage(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isEnabled && _connectedPlatforms.isNotEmpty ? _testPost : null,
                icon: const Icon(Icons.send),
                label: const Text('Send Test Post Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  String _getTimingLabel() {
    if (_postTimeOffset == 0) {
      return 'At opening time';
    } else if (_postTimeOffset < 0) {
      return '${_postTimeOffset.abs()} minutes before opening';
    } else {
      return '$_postTimeOffset minutes after opening';
    }
  }
  
  String _generatePreviewMessage() {
    final buffer = StringBuffer();
    
    buffer.writeln('🚚 [Your Truck Name] is OPEN! 🎉');
    buffer.writeln();
    
    if (_includeLocation) {
      buffer.writeln('📍 Location: [Current Location]');
    }
    
    buffer.writeln('⏰ Hours: 11:00 AM - 8:00 PM');
    buffer.writeln();
    
    if (_includeSpecials) {
      buffer.writeln("🌟 Today's Specials:");
      buffer.writeln('  • Special Item 1 - \$12.99');
      buffer.writeln('  • Special Item 2 - \$9.99');
      buffer.writeln();
    }
    
    buffer.writeln('Come hungry, leave happy! 😋');
    
    if (_includeHashtags) {
      buffer.writeln();
      buffer.write('#YourTruckName #FoodTruck #StreetFood #OpenNow');
    }
    
    return buffer.toString();
  }
  
  Future<void> _testPost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Test Post?'),
        content: const Text(
          'This will immediately post to all connected social media accounts. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Now'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      // TODO: Implement test post
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test post feature coming soon!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
  
  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email;
      case 'linkedin':
        return Icons.business;
      case 'tiktok':
        return Icons.music_note;
      default:
        return Icons.share;
    }
  }
  
  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Colors.purple;
      case 'facebook':
        return Colors.blue;
      case 'twitter':
        return Colors.lightBlue;
      case 'linkedin':
        return Colors.indigo;
      case 'tiktok':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
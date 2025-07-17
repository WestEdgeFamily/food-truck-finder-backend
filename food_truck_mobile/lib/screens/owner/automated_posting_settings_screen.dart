import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../services/oauth_service.dart';
import '../../utils/theme.dart';

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
  bool _postOnOpen = true;
  bool _postOnClose = false;
  bool _includeSpecials = true;
  bool _includeLocation = true;
  bool _includeHours = true;
  bool _includeHashtags = true;
  
  List<String> _customHashtags = [];
  final _hashtagController = TextEditingController();
  
  Map<String, bool> _platformSettings = {
    'facebook': true,
    'instagram': true,
    'twitter': true,
    'linkedin': true,
    'tiktok': false, // Disabled by default as it requires video
  };
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      // Load automated posting settings
      final settingsJson = await _storage.read(key: 'automated_posting_settings_${widget.truckId}');
      if (settingsJson != null) {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        setState(() {
          _isEnabled = settings['enabled'] ?? false;
          _postOnOpen = settings['postOnOpen'] ?? true;
          _postOnClose = settings['postOnClose'] ?? false;
          _includeSpecials = settings['includeSpecials'] ?? true;
          _includeLocation = settings['includeLocation'] ?? true;
          _includeHours = settings['includeHours'] ?? true;
          _includeHashtags = settings['includeHashtags'] ?? true;
          _customHashtags = List<String>.from(settings['customHashtags'] ?? []);
          
          if (settings['platformSettings'] != null) {
            _platformSettings = Map<String, bool>.from(settings['platformSettings']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading automated posting settings: $e');
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final settings = {
        'enabled': _isEnabled,
        'postOnOpen': _postOnOpen,
        'postOnClose': _postOnClose,
        'includeSpecials': _includeSpecials,
        'includeLocation': _includeLocation,
        'includeHours': _includeHours,
        'includeHashtags': _includeHashtags,
        'customHashtags': _customHashtags,
        'platformSettings': _platformSettings,
      };
      
      await _storage.write(
        key: 'automated_posting_settings_${widget.truckId}',
        value: jsonEncode(settings),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving automated posting settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Posting'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main toggle
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Enable Automated Posting',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Automatically post to social media when your truck opens or closes',
                ),
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // When to post
            Text(
              'When to Post',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('When truck opens'),
                    subtitle: const Text('Post opening hours and location'),
                    value: _postOnOpen,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _postOnOpen = value ?? true;
                      });
                    } : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('When truck closes'),
                    subtitle: const Text('Post closing message and tomorrow\'s schedule'),
                    value: _postOnClose,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _postOnClose = value ?? false;
                      });
                    } : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // What to include
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
                  CheckboxListTile(
                    title: const Text('Include location'),
                    subtitle: const Text('Add current location to posts'),
                    value: _includeLocation,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _includeLocation = value ?? true;
                      });
                    } : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Include hours'),
                    subtitle: const Text('Add opening and closing times'),
                    value: _includeHours,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _includeHours = value ?? true;
                      });
                    } : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Include specials'),
                    subtitle: const Text('Add today\'s featured items'),
                    value: _includeSpecials,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _includeSpecials = value ?? true;
                      });
                    } : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Include hashtags'),
                    subtitle: const Text('Add relevant hashtags to increase reach'),
                    value: _includeHashtags,
                    onChanged: _isEnabled ? (value) {
                      setState(() {
                        _includeHashtags = value ?? true;
                      });
                    } : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            
            // Custom hashtags
            if (_includeHashtags) ...[
              const SizedBox(height: 20),
              Text(
                'Custom Hashtags',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hashtagController,
                              decoration: const InputDecoration(
                                hintText: 'Add hashtag (without #)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              enabled: _isEnabled,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isEnabled ? () {
                              if (_hashtagController.text.isNotEmpty) {
                                setState(() {
                                  _customHashtags.add(_hashtagController.text);
                                  _hashtagController.clear();
                                });
                              }
                            } : null,
                            icon: const Icon(Icons.add_circle),
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _customHashtags.map((tag) => Chip(
                          label: Text('#$tag'),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: _isEnabled ? () {
                            setState(() {
                              _customHashtags.remove(tag);
                            });
                          } : null,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Platform selection
            Text(
              'Select Platforms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: OAuthService.getAllStoredAccounts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.warning,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No social media accounts connected',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Connect your accounts to enable automated posting',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/social-media-connect');
                            },
                            child: const Text('Connect Accounts'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final connectedAccounts = snapshot.data!;
                  return Column(
                    children: connectedAccounts.map((account) {
                      final platform = account['platform'] as String;
                      final userInfo = account['user_info'] as Map<String, dynamic>?;
                      String displayName = platform;
                      
                      switch (platform) {
                        case 'instagram':
                          displayName = userInfo?['username'] ?? 'Instagram';
                          break;
                        case 'facebook':
                          displayName = userInfo?['name'] ?? 'Facebook';
                          break;
                        case 'twitter':
                          displayName = '@${userInfo?['username'] ?? platform}';
                          break;
                        case 'linkedin':
                          final firstName = userInfo?['firstName']?['localized']?['en_US'] ?? '';
                          final lastName = userInfo?['lastName']?['localized']?['en_US'] ?? '';
                          displayName = '$firstName $lastName'.trim();
                          if (displayName.isEmpty) displayName = 'LinkedIn';
                          break;
                        case 'tiktok':
                          displayName = userInfo?['display_name'] ?? 'TikTok';
                          break;
                      }
                      
                      return CheckboxListTile(
                        title: Text(displayName),
                        subtitle: Text(_capitalize(platform)),
                        secondary: Icon(
                          _getPlatformIcon(platform),
                          color: _getPlatformColor(platform),
                        ),
                        value: _platformSettings[platform] ?? true,
                        onChanged: _isEnabled ? (value) {
                          setState(() {
                            _platformSettings[platform] = value ?? true;
                          });
                        } : null,
                        activeColor: AppTheme.primaryColor,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Posts are sent automatically based on your schedule\n'
                      '• Opening posts are sent within 5 minutes of opening time\n'
                      '• Each platform has its own requirements (Instagram needs images)\n'
                      '• You can manually post anytime from the dashboard\n'
                      '• Posts include emojis and formatting for better engagement',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
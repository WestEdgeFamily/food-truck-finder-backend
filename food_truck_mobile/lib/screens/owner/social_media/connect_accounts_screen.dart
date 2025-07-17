import 'package:flutter/material.dart';
import '../../../models/social_account.dart';
import '../../../services/oauth_service.dart';
import '../../../config/oauth_config.dart';
import '../../../utils/theme.dart';
import '../../oauth_webview_screen.dart';

class ConnectAccountsScreen extends StatefulWidget {
  final String userId;

  const ConnectAccountsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ConnectAccountsScreen> createState() => _ConnectAccountsScreenState();
}

class _ConnectAccountsScreenState extends State<ConnectAccountsScreen> {
  List<SocialAccount> _accounts = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availablePlatforms = [
    {
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Colors.purple,
      'description': 'Connect your Instagram Business account',
      'enabled': true,
    },
    {
      'name': 'Facebook',
      'icon': Icons.facebook,
      'color': Colors.blue,
      'description': 'Connect your Facebook Business page',
      'enabled': true,
    },
    {
      'name': 'Twitter',
      'icon': Icons.alternate_email,
      'color': Colors.lightBlue,
      'description': 'Connect your Twitter account',
      'enabled': true, // Now enabled!
    },
    {
      'name': 'LinkedIn',
      'icon': Icons.business,
      'color': Colors.indigo,
      'description': 'Connect your LinkedIn Company page',
      'enabled': true, // Now enabled!
    },
    {
      'name': 'TikTok',
      'icon': Icons.music_note,
      'color': Colors.black,
      'description': 'Connect your TikTok Business account',
      'enabled': true, // Now enabled!
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all stored accounts from secure storage
      final storedAccounts = await OAuthService.getAllStoredAccounts();
      
      // Convert to SocialAccount objects
      final accounts = <SocialAccount>[];
      for (final stored in storedAccounts) {
        final userInfo = stored['user_info'] as Map<String, dynamic>?;
        final platform = stored['platform'] as String;
        
        String accountName = 'Unknown';
        int followers = 0;
        
        // Extract platform-specific user info
        switch (platform) {
          case 'instagram':
            accountName = userInfo?['username'] ?? 'Unknown';
            followers = userInfo?['media_count'] ?? 0;
            break;
          case 'facebook':
            accountName = userInfo?['name'] ?? 'Unknown';
            // For Facebook, we might have multiple pages
            final accounts = userInfo?['accounts']?['data'] as List?;
            if (accounts != null && accounts.isNotEmpty) {
              followers = accounts.first['fan_count'] ?? 0;
            }
            break;
          case 'twitter':
            accountName = '@${userInfo?['username'] ?? 'unknown'}';
            followers = userInfo?['public_metrics']?['followers_count'] ?? 0;
            break;
          case 'linkedin':
            final firstName = userInfo?['firstName']?['localized']?['en_US'] ?? '';
            final lastName = userInfo?['lastName']?['localized']?['en_US'] ?? '';
            accountName = '$firstName $lastName'.trim();
            if (accountName.isEmpty) accountName = 'LinkedIn User';
            break;
          case 'tiktok':
            accountName = userInfo?['display_name'] ?? 'TikTok User';
            followers = userInfo?['follower_count'] ?? 0;
            break;
        }
        
        accounts.add(SocialAccount(
          id: stored['platform'],
          platform: stored['platform'],
          accountName: accountName,
          isActive: true,
          followers: followers,
          platformDisplayName: _capitalize(stored['platform']),
        ));
      }
      
      setState(() {
        _accounts = accounts;
      });
    } catch (e) {
      debugPrint('❌ Error loading accounts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accounts: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Accounts'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccounts,
            tooltip: 'Refresh accounts',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAccountsView(),
    );
  }

  Widget _buildAccountsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Social Media Accounts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect your social media accounts to manage all your posts from one place.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Configuration status
          _buildConfigurationStatus(),
          const SizedBox(height: 24),

          // Connected accounts section
          if (_accounts.isNotEmpty) ...[
            const Text(
              'Connected Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._accounts.map((account) => _buildConnectedAccountCard(account)),
            const SizedBox(height: 24),
          ],

          // Available platforms section
          const Text(
            'Available Platforms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._availablePlatforms.map((platform) => _buildPlatformCard(platform)),

          // Tips section
          const SizedBox(height: 32),
          _buildTipsSection(),
        ],
      ),
    );
  }

  Widget _buildConfigurationStatus() {
    final configuredPlatforms = <String>[];
    final unconfiguredPlatforms = <String>[];

    if (OAuthConfig.isInstagramConfigured) {
      configuredPlatforms.add('Instagram');
    } else {
      unconfiguredPlatforms.add('Instagram');
    }

    if (OAuthConfig.isFacebookConfigured) {
      configuredPlatforms.add('Facebook');
    } else {
      unconfiguredPlatforms.add('Facebook');
    }

    if (OAuthConfig.isTwitterConfigured) {
      configuredPlatforms.add('Twitter');
    } else {
      unconfiguredPlatforms.add('Twitter');
    }

    if (OAuthConfig.isLinkedinConfigured) {
      configuredPlatforms.add('LinkedIn');
    } else {
      unconfiguredPlatforms.add('LinkedIn');
    }

    if (OAuthConfig.isTiktokConfigured) {
      configuredPlatforms.add('TikTok');
    } else {
      unconfiguredPlatforms.add('TikTok');
    }

    return Card(
      color: unconfiguredPlatforms.isEmpty ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  unconfiguredPlatforms.isEmpty ? Icons.check_circle : Icons.warning,
                  color: unconfiguredPlatforms.isEmpty ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'OAuth Configuration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: unconfiguredPlatforms.isEmpty ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (configuredPlatforms.isNotEmpty)
              Text(
                'Configured: ${configuredPlatforms.join(', ')}',
                style: const TextStyle(color: Colors.green),
              ),
            if (unconfiguredPlatforms.isNotEmpty) ...[
              Text(
                'Not configured: ${unconfiguredPlatforms.join(', ')}',
                style: const TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update lib/config/oauth_config.dart with your app credentials to enable social media integration.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedAccountCard(SocialAccount account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getPlatformColor(account.platform),
              child: Icon(
                _getPlatformIcon(account.platform),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.accountName ?? account.platformDisplayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _capitalize(account.platform),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  if (account.followers > 0)
                    Text(
                      _getFollowerText(account.platform, account.followers),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: account.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    account.isActive ? 'Connected' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _disconnectAccount(account),
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard(Map<String, dynamic> platform) {
    final isConnected = _accounts.any(
      (account) => account.platform.toLowerCase() == platform['name'].toLowerCase(),
    );

    final isEnabled = platform['enabled'] as bool;
    final isConfigured = _isPlatformConfigured(platform['name']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: platform['color'],
              child: Icon(
                platform['icon'],
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    platform['description'],
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  if (!isEnabled)
                    const Text(
                      'Coming soon',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (!isConfigured)
                    const Text(
                      'Configure OAuth credentials first',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (isConnected)
                    const Text(
                      'Already connected',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isConnected || !isEnabled || !isConfigured
                  ? null
                  : () => _connectAccount(platform['name']),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.grey : platform['color'],
              ),
              child: Text(
                isConnected ? 'Connected' : 
                !isConfigured ? 'Configure' :
                (isEnabled ? 'Connect' : 'Soon'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips for Better Integration',
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
              '• Use business accounts for Instagram and TikTok for better features\n'
              '• Facebook Pages work better than personal profiles for businesses\n'
              '• LinkedIn Company pages have more posting capabilities\n'
              '• Twitter verified accounts get higher reach\n'
              '• Keep your account information up to date for best results',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _getFollowerText(String platform, int count) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return '$count posts';
      case 'facebook':
        return '$count page likes';
      case 'twitter':
        return '$count followers';
      case 'linkedin':
        return 'Professional network';
      case 'tiktok':
        return '$count followers';
      default:
        return '$count followers';
    }
  }

  bool _isPlatformConfigured(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return OAuthConfig.isInstagramConfigured;
      case 'facebook':
        return OAuthConfig.isFacebookConfigured;
      case 'twitter':
        return OAuthConfig.isTwitterConfigured;
      case 'linkedin':
        return OAuthConfig.isLinkedinConfigured;
      case 'tiktok':
        return OAuthConfig.isTiktokConfigured;
      default:
        return false;
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

  Future<void> _connectAccount(String platform) async {
    try {
      debugPrint('🔗 Connecting to $platform...');
      
      Map<String, String> authData;
      String redirectUri;
      
      switch (platform.toLowerCase()) {
        case 'instagram':
          authData = await OAuthService.generateInstagramAuthUrl();
          redirectUri = OAuthConfig.instagramRedirectUri;
          break;
        case 'facebook':
          authData = await OAuthService.generateFacebookAuthUrl();
          redirectUri = OAuthConfig.facebookRedirectUri;
          break;
        case 'twitter':
          authData = await OAuthService.generateTwitterAuthUrl();
          redirectUri = OAuthConfig.twitterRedirectUri;
          break;
        case 'linkedin':
          authData = await OAuthService.generateLinkedInAuthUrl();
          redirectUri = OAuthConfig.linkedinRedirectUri;
          break;
        case 'tiktok':
          authData = await OAuthService.generateTikTokAuthUrl();
          redirectUri = OAuthConfig.tiktokRedirectUri;
          break;
        default:
          throw Exception('Platform $platform not supported yet');
      }

      final authUrl = authData['url']!;

      // Navigate to OAuth WebView
      if (mounted) {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => OAuthWebViewScreen(
              platform: platform,
              authUrl: authUrl,
              redirectUri: redirectUri,
            ),
          ),
        );

        if (result != null) {
          if (result['success'] == true) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully connected to $platform!'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () => _loadAccounts(),
                ),
              ),
            );
            
            // Reload accounts to show the new connection
            await _loadAccounts();
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to connect to $platform: ${result['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error connecting to $platform: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to $platform: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectAccount(SocialAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Account'),
        content: Text(
          'Are you sure you want to disconnect ${account.accountName ?? account.platformDisplayName}?\n\nThis will remove access to post and view analytics for this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Remove tokens from secure storage
        await OAuthService.removeStoredTokens(account.platform);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_capitalize(account.platform)} account disconnected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Reload accounts to update the UI
        await _loadAccounts();
      } catch (e) {
        debugPrint('❌ Error disconnecting account: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to disconnect account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
} 
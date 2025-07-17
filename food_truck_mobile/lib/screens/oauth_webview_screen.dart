import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/oauth_service.dart';
import '../utils/theme.dart';

class OAuthWebViewScreen extends StatefulWidget {
  final String platform;
  final String authUrl;
  final String redirectUri;

  const OAuthWebViewScreen({
    super.key,
    required this.platform,
    required this.authUrl,
    required this.redirectUri,
  });

  @override
  State<OAuthWebViewScreen> createState() => _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends State<OAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('🌐 Page started loading: $url');
            
            // Check if this is our callback URL
            if (url.startsWith(widget.redirectUri)) {
              _handleCallback(url);
            }
          },
          onPageFinished: (url) {
            debugPrint('🌐 Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            debugPrint('🌐 WebView error: ${error.description}');
            setState(() {
              _error = 'Failed to load authentication page: ${error.description}';
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('🌐 Navigation request: $url');
            
            // Allow navigation to OAuth providers and our callback
            if (_isAllowedUrl(url)) {
              return NavigationDecision.navigate;
            }
            
            // Block other external navigation
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  bool _isAllowedUrl(String url) {
    final allowedDomains = [
      // Instagram/Facebook
      'https://api.instagram.com',
      'https://www.instagram.com',
      'https://www.facebook.com',
      'https://graph.facebook.com',
      'https://m.facebook.com',
      
      // Twitter
      'https://twitter.com',
      'https://api.twitter.com',
      'https://mobile.twitter.com',
      
      // LinkedIn
      'https://www.linkedin.com',
      'https://api.linkedin.com',
      
      // TikTok
      'https://www.tiktok.com',
      'https://open-api.tiktok.com',
      
      // Our callback
      widget.redirectUri,
    ];

    return allowedDomains.any((domain) => url.startsWith(domain));
  }

  Future<void> _handleCallback(String callbackUrl) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      switch (widget.platform.toLowerCase()) {
        case 'instagram':
          result = await OAuthService.handleInstagramCallback(callbackUrl);
          break;
        case 'facebook':
          result = await OAuthService.handleFacebookCallback(callbackUrl);
          break;
        case 'twitter':
          result = await OAuthService.handleTwitterCallback(callbackUrl);
          break;
        case 'linkedin':
          result = await OAuthService.handleLinkedInCallback(callbackUrl);
          break;
        case 'tiktok':
          result = await OAuthService.handleTikTokCallback(callbackUrl);
          break;
        default:
          throw Exception('Unsupported platform: ${widget.platform}');
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      debugPrint('❌ OAuth callback error: $e');
      if (mounted) {
        setState(() {
          _error = 'Authentication failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect ${_capitalize(widget.platform)}'),
        backgroundColor: _getPlatformColor(widget.platform),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop({
              'success': false,
              'error': 'User cancelled authentication',
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error != null)
            _buildErrorView()
          else
            WebViewWidget(controller: _controller),
          
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPlatformColor(widget.platform),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connecting to ${_capitalize(widget.platform)}...',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please authorize the app to continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: _getPlatformColor(widget.platform),
            ),
            const SizedBox(height: 16),
            Text(
              'Authentication Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _getPlatformColor(widget.platform),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'success': false,
                      'error': _error,
                    });
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                    });
                    _controller.reload();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getPlatformColor(widget.platform),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        return AppTheme.primaryColor;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
} 
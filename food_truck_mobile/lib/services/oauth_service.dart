import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/oauth_config.dart';

class OAuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Instagram OAuth Configuration
  static const String _instagramAuthUrl = 'https://api.instagram.com/oauth/authorize';
  static const String _instagramTokenUrl = 'https://api.instagram.com/oauth/access_token';
  static const String _instagramScope = 'user_profile,user_media';

  // Facebook OAuth Configuration
  static const String _facebookAuthUrl = 'https://www.facebook.com/v18.0/dialog/oauth';
  static const String _facebookTokenUrl = 'https://graph.facebook.com/v18.0/oauth/access_token';
  static const String _facebookScope = 'pages_manage_posts,pages_read_engagement,instagram_basic,instagram_content_publish,publish_to_groups';

  // Twitter OAuth Configuration
  static const String _twitterAuthUrl = 'https://twitter.com/i/oauth2/authorize';
  static const String _twitterTokenUrl = 'https://api.twitter.com/2/oauth2/token';
  static const String _twitterScope = 'tweet.read tweet.write users.read offline.access';

  // LinkedIn OAuth Configuration
  static const String _linkedinAuthUrl = 'https://www.linkedin.com/oauth/v2/authorization';
  static const String _linkedinTokenUrl = 'https://www.linkedin.com/oauth/v2/accessToken';
  static const String _linkedinScope = 'r_liteprofile r_emailaddress w_member_social';

  // TikTok OAuth Configuration
  static const String _tiktokAuthUrl = 'https://www.tiktok.com/auth/authorize/';
  static const String _tiktokTokenUrl = 'https://open-api.tiktok.com/oauth/access_token/';
  static const String _tiktokScope = 'user.info.basic video.publish video.upload';

  // PKCE Code Generation
  static String _generateCodeVerifier() {
    const String charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final Random random = Random.secure();
    return List.generate(128, (i) => charset[random.nextInt(charset.length)]).join();
  }

  static String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // Generate OAuth URLs
  static Future<Map<String, String>> generateInstagramAuthUrl() async {
    if (!OAuthConfig.isInstagramConfigured) {
      throw Exception('Instagram OAuth not configured. Please update lib/config/oauth_config.dart');
    }

    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateRandomString(32);

    // Store code verifier and state for later verification
    await _storage.write(key: 'instagram_code_verifier', value: codeVerifier);
    await _storage.write(key: 'instagram_state', value: state);

    final uri = Uri.parse(_instagramAuthUrl).replace(queryParameters: {
      'client_id': OAuthConfig.instagramClientId,
      'redirect_uri': OAuthConfig.instagramRedirectUri,
      'scope': _instagramScope,
      'response_type': 'code',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
    });

    return {
      'url': uri.toString(),
      'state': state,
    };
  }

  static Future<Map<String, String>> generateFacebookAuthUrl() async {
    if (!OAuthConfig.isFacebookConfigured) {
      throw Exception('Facebook OAuth not configured. Please update lib/config/oauth_config.dart');
    }

    final state = _generateRandomString(32);
    await _storage.write(key: 'facebook_state', value: state);

    final uri = Uri.parse(_facebookAuthUrl).replace(queryParameters: {
      'client_id': OAuthConfig.facebookClientId,
      'redirect_uri': OAuthConfig.facebookRedirectUri,
      'scope': _facebookScope,
      'response_type': 'code',
      'state': state,
    });

    return {
      'url': uri.toString(),
      'state': state,
    };
  }

  static Future<Map<String, String>> generateTwitterAuthUrl() async {
    if (!OAuthConfig.isTwitterConfigured) {
      throw Exception('Twitter OAuth not configured. Please update lib/config/oauth_config.dart');
    }

    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateRandomString(32);

    await _storage.write(key: 'twitter_code_verifier', value: codeVerifier);
    await _storage.write(key: 'twitter_state', value: state);

    final uri = Uri.parse(_twitterAuthUrl).replace(queryParameters: {
      'response_type': 'code',
      'client_id': OAuthConfig.twitterApiKey,
      'redirect_uri': OAuthConfig.twitterRedirectUri,
      'scope': _twitterScope,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    return {
      'url': uri.toString(),
      'state': state,
    };
  }

  static Future<Map<String, String>> generateLinkedInAuthUrl() async {
    if (!OAuthConfig.isLinkedinConfigured) {
      throw Exception('LinkedIn OAuth not configured. Please update lib/config/oauth_config.dart');
    }

    final state = _generateRandomString(32);
    await _storage.write(key: 'linkedin_state', value: state);

    final uri = Uri.parse(_linkedinAuthUrl).replace(queryParameters: {
      'response_type': 'code',
      'client_id': OAuthConfig.linkedinClientId,
      'redirect_uri': OAuthConfig.linkedinRedirectUri,
      'state': state,
      'scope': _linkedinScope,
    });

    return {
      'url': uri.toString(),
      'state': state,
    };
  }

  static Future<Map<String, String>> generateTikTokAuthUrl() async {
    if (!OAuthConfig.isTiktokConfigured) {
      throw Exception('TikTok OAuth not configured. Please update lib/config/oauth_config.dart');
    }

    final state = _generateRandomString(32);
    await _storage.write(key: 'tiktok_state', value: state);

    final uri = Uri.parse(_tiktokAuthUrl).replace(queryParameters: {
      'client_key': OAuthConfig.tiktokClientKey,
      'scope': _tiktokScope,
      'response_type': 'code',
      'redirect_uri': OAuthConfig.tiktokRedirectUri,
      'state': state,
    });

    return {
      'url': uri.toString(),
      'state': state,
    };
  }

  // Handle OAuth Callbacks
  static Future<Map<String, dynamic>> handleInstagramCallback(String callbackUrl) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        throw Exception('OAuth error: $error');
      }

      if (code == null || state == null) {
        throw Exception('Missing authorization code or state');
      }

      // Verify state
      final storedState = await _storage.read(key: 'instagram_state');
      if (state != storedState) {
        throw Exception('Invalid state parameter');
      }

      // Exchange code for access token
      final codeVerifier = await _storage.read(key: 'instagram_code_verifier');
      if (codeVerifier == null) {
        throw Exception('Missing code verifier');
      }

      final tokenResponse = await _exchangeCodeForToken(
        platform: 'instagram',
        code: code,
        codeVerifier: codeVerifier,
      );

      // Get user profile information
      final userInfo = await _getInstagramUserInfo(tokenResponse['access_token']);

      // Store tokens securely
      await _storeTokens('instagram', {
        'access_token': tokenResponse['access_token'],
        'user_id': tokenResponse['user_id'],
        'expires_in': tokenResponse['expires_in'],
        'user_info': userInfo,
      });

      // Clean up temporary storage
      await _storage.delete(key: 'instagram_code_verifier');
      await _storage.delete(key: 'instagram_state');

      return {
        'success': true,
        'platform': 'instagram',
        'user_info': userInfo,
        'access_token': tokenResponse['access_token'],
      };
    } catch (e) {
      debugPrint('❌ Instagram OAuth callback error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> handleFacebookCallback(String callbackUrl) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        throw Exception('OAuth error: $error');
      }

      if (code == null || state == null) {
        throw Exception('Missing authorization code or state');
      }

      // Verify state
      final storedState = await _storage.read(key: 'facebook_state');
      if (state != storedState) {
        throw Exception('Invalid state parameter');
      }

      // Exchange code for access token
      final tokenResponse = await _exchangeCodeForToken(
        platform: 'facebook',
        code: code,
      );

      // Get user profile and pages information
      final userInfo = await _getFacebookUserInfo(tokenResponse['access_token']);

      // Store tokens securely
      await _storeTokens('facebook', {
        'access_token': tokenResponse['access_token'],
        'expires_in': tokenResponse['expires_in'],
        'user_info': userInfo,
      });

      // Clean up temporary storage
      await _storage.delete(key: 'facebook_state');

      return {
        'success': true,
        'platform': 'facebook',
        'user_info': userInfo,
        'access_token': tokenResponse['access_token'],
      };
    } catch (e) {
      debugPrint('❌ Facebook OAuth callback error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> handleTwitterCallback(String callbackUrl) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        throw Exception('OAuth error: $error');
      }

      if (code == null || state == null) {
        throw Exception('Missing authorization code or state');
      }

      // Verify state
      final storedState = await _storage.read(key: 'twitter_state');
      if (state != storedState) {
        throw Exception('Invalid state parameter');
      }

      // Exchange code for access token
      final codeVerifier = await _storage.read(key: 'twitter_code_verifier');
      if (codeVerifier == null) {
        throw Exception('Missing code verifier');
      }

      final tokenResponse = await _exchangeCodeForToken(
        platform: 'twitter',
        code: code,
        codeVerifier: codeVerifier,
      );

      // Get user profile information
      final userInfo = await _getTwitterUserInfo(tokenResponse['access_token']);

      // Store tokens securely
      await _storeTokens('twitter', {
        'access_token': tokenResponse['access_token'],
        'refresh_token': tokenResponse['refresh_token'],
        'expires_in': tokenResponse['expires_in'],
        'user_info': userInfo,
      });

      // Clean up temporary storage
      await _storage.delete(key: 'twitter_code_verifier');
      await _storage.delete(key: 'twitter_state');

      return {
        'success': true,
        'platform': 'twitter',
        'user_info': userInfo,
        'access_token': tokenResponse['access_token'],
      };
    } catch (e) {
      debugPrint('❌ Twitter OAuth callback error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> handleLinkedInCallback(String callbackUrl) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        throw Exception('OAuth error: $error');
      }

      if (code == null || state == null) {
        throw Exception('Missing authorization code or state');
      }

      // Verify state
      final storedState = await _storage.read(key: 'linkedin_state');
      if (state != storedState) {
        throw Exception('Invalid state parameter');
      }

      // Exchange code for access token
      final tokenResponse = await _exchangeCodeForToken(
        platform: 'linkedin',
        code: code,
      );

      // Get user profile information
      final userInfo = await _getLinkedInUserInfo(tokenResponse['access_token']);

      // Store tokens securely
      await _storeTokens('linkedin', {
        'access_token': tokenResponse['access_token'],
        'expires_in': tokenResponse['expires_in'],
        'user_info': userInfo,
      });

      // Clean up temporary storage
      await _storage.delete(key: 'linkedin_state');

      return {
        'success': true,
        'platform': 'linkedin',
        'user_info': userInfo,
        'access_token': tokenResponse['access_token'],
      };
    } catch (e) {
      debugPrint('❌ LinkedIn OAuth callback error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> handleTikTokCallback(String callbackUrl) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        throw Exception('OAuth error: $error');
      }

      if (code == null || state == null) {
        throw Exception('Missing authorization code or state');
      }

      // Verify state
      final storedState = await _storage.read(key: 'tiktok_state');
      if (state != storedState) {
        throw Exception('Invalid state parameter');
      }

      // Exchange code for access token
      final tokenResponse = await _exchangeCodeForToken(
        platform: 'tiktok',
        code: code,
      );

      // Get user profile information
      final userInfo = await _getTikTokUserInfo(tokenResponse['access_token']);

      // Store tokens securely
      await _storeTokens('tiktok', {
        'access_token': tokenResponse['access_token'],
        'refresh_token': tokenResponse['refresh_token'],
        'expires_in': tokenResponse['expires_in'],
        'user_info': userInfo,
      });

      // Clean up temporary storage
      await _storage.delete(key: 'tiktok_state');

      return {
        'success': true,
        'platform': 'tiktok',
        'user_info': userInfo,
        'access_token': tokenResponse['access_token'],
      };
    } catch (e) {
      debugPrint('❌ TikTok OAuth callback error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Token Exchange
  static Future<Map<String, dynamic>> _exchangeCodeForToken({
    required String platform,
    required String code,
    String? codeVerifier,
  }) async {
    late String tokenUrl;
    late Map<String, String> body;
    late Map<String, String> headers;

    switch (platform) {
      case 'instagram':
        tokenUrl = _instagramTokenUrl;
        headers = {'Content-Type': 'application/x-www-form-urlencoded'};
        body = {
          'client_id': OAuthConfig.instagramClientId,
          'client_secret': OAuthConfig.instagramClientSecret,
          'redirect_uri': OAuthConfig.instagramRedirectUri,
          'code': code,
          'grant_type': 'authorization_code',
          if (codeVerifier != null) 'code_verifier': codeVerifier,
        };
        break;
      case 'facebook':
        tokenUrl = _facebookTokenUrl;
        headers = {'Content-Type': 'application/x-www-form-urlencoded'};
        body = {
          'client_id': OAuthConfig.facebookClientId,
          'client_secret': OAuthConfig.facebookClientSecret,
          'redirect_uri': OAuthConfig.facebookRedirectUri,
          'code': code,
          'grant_type': 'authorization_code',
        };
        break;
      case 'twitter':
        tokenUrl = _twitterTokenUrl;
        headers = {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${OAuthConfig.twitterApiKey}:${OAuthConfig.twitterApiSecret}'))}',
        };
        body = {
          'code': code,
          'grant_type': 'authorization_code',
          'client_id': OAuthConfig.twitterApiKey,
          'redirect_uri': OAuthConfig.twitterRedirectUri,
          if (codeVerifier != null) 'code_verifier': codeVerifier,
        };
        break;
      case 'linkedin':
        tokenUrl = _linkedinTokenUrl;
        headers = {'Content-Type': 'application/x-www-form-urlencoded'};
        body = {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': OAuthConfig.linkedinClientId,
          'client_secret': OAuthConfig.linkedinClientSecret,
          'redirect_uri': OAuthConfig.linkedinRedirectUri,
        };
        break;
      case 'tiktok':
        tokenUrl = _tiktokTokenUrl;
        headers = {'Content-Type': 'application/x-www-form-urlencoded'};
        body = {
          'client_key': OAuthConfig.tiktokClientKey,
          'client_secret': OAuthConfig.tiktokClientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': OAuthConfig.tiktokRedirectUri,
        };
        break;
      default:
        throw Exception('Unsupported platform: $platform');
    }

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Token exchange failed: ${response.body}');
    }
  }

  // Get User Information
  static Future<Map<String, dynamic>> _getInstagramUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://graph.instagram.com/me?fields=id,username,media_count&access_token=$accessToken'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get Instagram user info: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> _getFacebookUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://graph.facebook.com/me?fields=id,name,accounts{id,name,access_token,instagram_business_account,fan_count}&access_token=$accessToken'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get Facebook user info: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> _getTwitterUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.twitter.com/2/users/me?user.fields=id,name,username,public_metrics'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to get Twitter user info: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> _getLinkedInUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.linkedin.com/v2/people/~?projection=(id,firstName,lastName,profilePicture(displayImage~:playableStreams))'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get LinkedIn user info: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> _getTikTokUserInfo(String accessToken) async {
    final response = await http.post(
      Uri.parse('https://open-api.tiktok.com/user/info/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'access_token': accessToken,
        'fields': ['open_id', 'union_id', 'avatar_url', 'display_name', 'follower_count', 'following_count', 'likes_count', 'video_count'],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['user'];
    } else {
      throw Exception('Failed to get TikTok user info: ${response.body}');
    }
  }

  // Token Storage
  static Future<void> _storeTokens(String platform, Map<String, dynamic> tokens) async {
    final tokenData = json.encode(tokens);
    await _storage.write(key: '${platform}_tokens', value: tokenData);
  }

  static Future<Map<String, dynamic>?> getStoredTokens(String platform) async {
    final tokenData = await _storage.read(key: '${platform}_tokens');
    if (tokenData != null) {
      return json.decode(tokenData);
    }
    return null;
  }

  static Future<void> removeStoredTokens(String platform) async {
    await _storage.delete(key: '${platform}_tokens');
  }

  // Refresh Tokens
  static Future<Map<String, dynamic>?> refreshToken(String platform) async {
    try {
      final tokens = await getStoredTokens(platform);
      if (tokens == null) {
        return null;
      }

      final refreshToken = tokens['refresh_token'];
      if (refreshToken == null) {
        return null;
      }

      Map<String, String> body;
      String tokenUrl;
      Map<String, String> headers;

      switch (platform) {
        case 'instagram':
          return await refreshInstagramToken(refreshToken);
        case 'twitter':
          tokenUrl = _twitterTokenUrl;
          headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': 'Basic ${base64Encode(utf8.encode('${OAuthConfig.twitterApiKey}:${OAuthConfig.twitterApiSecret}'))}',
          };
          body = {
            'refresh_token': refreshToken,
            'grant_type': 'refresh_token',
            'client_id': OAuthConfig.twitterApiKey,
          };
          break;
        case 'tiktok':
          tokenUrl = _tiktokTokenUrl;
          headers = {'Content-Type': 'application/x-www-form-urlencoded'};
          body = {
            'client_key': OAuthConfig.tiktokClientKey,
            'client_secret': OAuthConfig.tiktokClientSecret,
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
          };
          break;
        default:
          return null;
      }

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final newTokens = json.decode(response.body);
        await _storeTokens(platform, {
          ...tokens,
          ...newTokens,
        });
        return newTokens;
      }
    } catch (e) {
      debugPrint('❌ Token refresh failed for $platform: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> refreshInstagramToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://graph.instagram.com/refresh_access_token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'ig_refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        await _storeTokens('instagram', tokenData);
        return tokenData;
      }
    } catch (e) {
      debugPrint('❌ Instagram token refresh failed: $e');
    }
    return null;
  }

  // Utility Methods
  static String _generateRandomString(int length) {
    const String charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random.secure();
    return List.generate(length, (i) => charset[random.nextInt(charset.length)]).join();
  }

  // Validate Access Token
  static Future<bool> validateToken(String platform, String accessToken) async {
    try {
      switch (platform) {
        case 'instagram':
          final response = await http.get(
            Uri.parse('https://graph.instagram.com/me?access_token=$accessToken'),
          );
          return response.statusCode == 200;
        case 'facebook':
          final response = await http.get(
            Uri.parse('https://graph.facebook.com/me?access_token=$accessToken'),
          );
          return response.statusCode == 200;
        case 'twitter':
          final response = await http.get(
            Uri.parse('https://api.twitter.com/2/users/me'),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          return response.statusCode == 200;
        case 'linkedin':
          final response = await http.get(
            Uri.parse('https://api.linkedin.com/v2/people/~'),
            headers: {'Authorization': 'Bearer $accessToken'},
          );
          return response.statusCode == 200;
        case 'tiktok':
          final response = await http.post(
            Uri.parse('https://open-api.tiktok.com/user/info/'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'access_token': accessToken,
              'fields': ['open_id'],
            }),
          );
          return response.statusCode == 200;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get all stored accounts
  static Future<List<Map<String, dynamic>>> getAllStoredAccounts() async {
    final accounts = <Map<String, dynamic>>[];
    final platforms = ['instagram', 'facebook', 'twitter', 'linkedin', 'tiktok'];

    for (final platform in platforms) {
      final tokens = await getStoredTokens(platform);
      if (tokens != null) {
        accounts.add({
          'platform': platform,
          'tokens': tokens,
          'user_info': tokens['user_info'],
        });
      }
    }

    return accounts;
  }

  // Check if platform is connected
  static Future<bool> isPlatformConnected(String platform) async {
    final tokens = await getStoredTokens(platform);
    return tokens != null;
  }
} 
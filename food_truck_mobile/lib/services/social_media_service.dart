import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/social_account.dart';
import 'api_service.dart';

/// Service to handle real social media OAuth connections and posting
class SocialMediaService {
  static const storage = FlutterSecureStorage();
  
  // OAuth URLs for each platform
  static const String facebookOAuthUrl = 'https://www.facebook.com/v18.0/dialog/oauth';
  static const String instagramOAuthUrl = 'https://api.instagram.com/oauth/authorize';
  static const String twitterOAuthUrl = 'https://twitter.com/i/oauth2/authorize';
  
  // Your OAuth app credentials (these should be in environment variables in production)
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
  static const String instagramClientId = 'YOUR_INSTAGRAM_CLIENT_ID';
  static const String twitterClientId = 'YOUR_TWITTER_CLIENT_ID';
  
  // Redirect URI for OAuth callbacks
  static const String redirectUri = 'foodtruckapp://oauth/callback';
  
  /// Connect Facebook account
  static Future<Map<String, dynamic>> connectFacebook(String truckId) async {
    try {
      // Facebook OAuth permissions needed
      const permissions = [
        'pages_show_list',
        'pages_read_engagement',
        'pages_manage_posts',
        'pages_manage_engagement',
        'business_management',
      ].join(',');
      
      final authUrl = Uri.parse('$facebookOAuthUrl'
          '?client_id=$facebookAppId'
          '&redirect_uri=$redirectUri'
          '&scope=$permissions'
          '&response_type=code'
          '&state=facebook_$truckId');
      
      // Launch OAuth flow
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        return {
          'success': true,
          'message': 'Please complete Facebook login in your browser',
        };
      } else {
        throw Exception('Could not launch Facebook OAuth');
      }
    } catch (e) {
      debugPrint('Facebook connection error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Connect Instagram account (Business/Creator accounts only)
  static Future<Map<String, dynamic>> connectInstagram(String truckId) async {
    try {
      // Instagram Basic Display API permissions
      const scope = 'user_profile,user_media';
      
      final authUrl = Uri.parse('$instagramOAuthUrl'
          '?client_id=$instagramClientId'
          '&redirect_uri=$redirectUri'
          '&scope=$scope'
          '&response_type=code'
          '&state=instagram_$truckId');
      
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        return {
          'success': true,
          'message': 'Please complete Instagram login in your browser',
        };
      } else {
        throw Exception('Could not launch Instagram OAuth');
      }
    } catch (e) {
      debugPrint('Instagram connection error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Connect Twitter/X account
  static Future<Map<String, dynamic>> connectTwitter(String truckId) async {
    try {
      // Twitter OAuth 2.0 scopes
      const scope = 'tweet.read tweet.write users.read offline.access';
      
      final authUrl = Uri.parse('$twitterOAuthUrl'
          '?response_type=code'
          '&client_id=$twitterClientId'
          '&redirect_uri=$redirectUri'
          '&scope=$scope'
          '&state=twitter_$truckId'
          '&code_challenge=challenge'
          '&code_challenge_method=plain');
      
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        return {
          'success': true,
          'message': 'Please complete Twitter login in your browser',
        };
      } else {
        throw Exception('Could not launch Twitter OAuth');
      }
    } catch (e) {
      debugPrint('Twitter connection error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Handle OAuth callback
  static Future<Map<String, dynamic>> handleOAuthCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      
      if (code == null || state == null) {
        throw Exception('Invalid OAuth callback');
      }
      
      // Extract platform and truckId from state
      final parts = state.split('_');
      final platform = parts[0];
      final truckId = parts[1];
      
      // Exchange code for access token based on platform
      switch (platform) {
        case 'facebook':
          return await _exchangeFacebookToken(code, truckId);
        case 'instagram':
          return await _exchangeInstagramToken(code, truckId);
        case 'twitter':
          return await _exchangeTwitterToken(code, truckId);
        default:
          throw Exception('Unknown platform: $platform');
      }
    } catch (e) {
      debugPrint('OAuth callback error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Exchange Facebook authorization code for access token
  static Future<Map<String, dynamic>> _exchangeFacebookToken(String code, String truckId) async {
    try {
      // Exchange code for user access token
      final tokenResponse = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/oauth/access_token'
            '?client_id=$facebookAppId'
            '&redirect_uri=$redirectUri'
            '&client_secret=YOUR_FACEBOOK_APP_SECRET'
            '&code=$code'),
      );
      
      if (tokenResponse.statusCode == 200) {
        final tokenData = jsonDecode(tokenResponse.body);
        final accessToken = tokenData['access_token'];
        
        // Get user's Facebook pages
        final pagesResponse = await http.get(
          Uri.parse('https://graph.facebook.com/v18.0/me/accounts'
              '?access_token=$accessToken'),
        );
        
        if (pagesResponse.statusCode == 200) {
          final pagesData = jsonDecode(pagesResponse.body);
          final pages = pagesData['data'] as List;
          
          // Store tokens securely
          await storage.write(key: 'facebook_token_$truckId', value: accessToken);
          
          // Let user select which page to connect
          return {
            'success': true,
            'platform': 'facebook',
            'pages': pages,
            'truckId': truckId,
          };
        }
      }
      
      throw Exception('Failed to exchange Facebook token');
    } catch (e) {
      debugPrint('Facebook token exchange error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Exchange Instagram authorization code for access token
  static Future<Map<String, dynamic>> _exchangeInstagramToken(String code, String truckId) async {
    try {
      final tokenResponse = await http.post(
        Uri.parse('https://api.instagram.com/oauth/access_token'),
        body: {
          'client_id': instagramClientId,
          'client_secret': 'YOUR_INSTAGRAM_CLIENT_SECRET',
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
          'code': code,
        },
      );
      
      if (tokenResponse.statusCode == 200) {
        final tokenData = jsonDecode(tokenResponse.body);
        final accessToken = tokenData['access_token'];
        final userId = tokenData['user_id'];
        
        // Exchange short-lived token for long-lived token
        final longLivedResponse = await http.get(
          Uri.parse('https://graph.instagram.com/access_token'
              '?grant_type=ig_exchange_token'
              '&client_secret=YOUR_INSTAGRAM_CLIENT_SECRET'
              '&access_token=$accessToken'),
        );
        
        if (longLivedResponse.statusCode == 200) {
          final longLivedData = jsonDecode(longLivedResponse.body);
          final longLivedToken = longLivedData['access_token'];
          
          // Store token securely
          await storage.write(key: 'instagram_token_$truckId', value: longLivedToken);
          await storage.write(key: 'instagram_user_id_$truckId', value: userId.toString());
          
          return {
            'success': true,
            'platform': 'instagram',
            'userId': userId,
            'truckId': truckId,
          };
        }
      }
      
      throw Exception('Failed to exchange Instagram token');
    } catch (e) {
      debugPrint('Instagram token exchange error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Exchange Twitter authorization code for access token
  static Future<Map<String, dynamic>> _exchangeTwitterToken(String code, String truckId) async {
    try {
      final tokenResponse = await http.post(
        Uri.parse('https://api.twitter.com/2/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$twitterClientId:YOUR_TWITTER_CLIENT_SECRET'))}',
        },
        body: {
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
          'code_verifier': 'challenge',
        },
      );
      
      if (tokenResponse.statusCode == 200) {
        final tokenData = jsonDecode(tokenResponse.body);
        final accessToken = tokenData['access_token'];
        final refreshToken = tokenData['refresh_token'];
        
        // Store tokens securely
        await storage.write(key: 'twitter_token_$truckId', value: accessToken);
        await storage.write(key: 'twitter_refresh_token_$truckId', value: refreshToken);
        
        return {
          'success': true,
          'platform': 'twitter',
          'truckId': truckId,
        };
      }
      
      throw Exception('Failed to exchange Twitter token');
    } catch (e) {
      debugPrint('Twitter token exchange error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Post to all connected social media accounts
  static Future<Map<String, dynamic>> postToAllPlatforms({
    required String truckId,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? locationData,
  }) async {
    final results = <String, dynamic>{};
    
    // Get connected accounts from backend
    try {
      final accountsData = await ApiService.getSocialAccounts(truckId);
      final accounts = accountsData['accounts'] as List? ?? [];
      
      for (var account in accounts) {
        final platform = account['platform'];
        final accountId = account['id'];
        
        switch (platform) {
          case 'facebook':
            results['facebook'] = await _postToFacebook(truckId, accountId, message, imageUrl);
            break;
          case 'instagram':
            results['instagram'] = await _postToInstagram(truckId, accountId, message, imageUrl);
            break;
          case 'twitter':
            results['twitter'] = await _postToTwitter(truckId, message, imageUrl);
            break;
        }
      }
      
      return {
        'success': true,
        'results': results,
      };
    } catch (e) {
      debugPrint('Error posting to social media: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Post to Facebook
  static Future<Map<String, dynamic>> _postToFacebook(
    String truckId,
    String pageId,
    String message,
    String? imageUrl,
  ) async {
    try {
      final token = await storage.read(key: 'facebook_token_$truckId');
      if (token == null) throw Exception('Facebook not connected');
      
      final endpoint = imageUrl != null
          ? 'https://graph.facebook.com/v18.0/$pageId/photos'
          : 'https://graph.facebook.com/v18.0/$pageId/feed';
      
      final body = imageUrl != null
          ? {
              'message': message,
              'url': imageUrl,
              'access_token': token,
            }
          : {
              'message': message,
              'access_token': token,
            };
      
      final response = await http.post(
        Uri.parse(endpoint),
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'postId': data['id'],
        };
      } else {
        throw Exception('Facebook post failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Facebook post error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Post to Instagram (requires Instagram Business Account)
  static Future<Map<String, dynamic>> _postToInstagram(
    String truckId,
    String accountId,
    String caption,
    String? imageUrl,
  ) async {
    try {
      final token = await storage.read(key: 'instagram_token_$truckId');
      final userId = await storage.read(key: 'instagram_user_id_$truckId');
      if (token == null || userId == null) throw Exception('Instagram not connected');
      
      if (imageUrl == null) {
        return {
          'success': false,
          'error': 'Instagram requires an image to post',
        };
      }
      
      // Step 1: Create media container
      final createResponse = await http.post(
        Uri.parse('https://graph.facebook.com/v18.0/$userId/media'),
        body: {
          'image_url': imageUrl,
          'caption': caption,
          'access_token': token,
        },
      );
      
      if (createResponse.statusCode == 200) {
        final createData = jsonDecode(createResponse.body);
        final creationId = createData['id'];
        
        // Step 2: Publish the media
        final publishResponse = await http.post(
          Uri.parse('https://graph.facebook.com/v18.0/$userId/media_publish'),
          body: {
            'creation_id': creationId,
            'access_token': token,
          },
        );
        
        if (publishResponse.statusCode == 200) {
          final publishData = jsonDecode(publishResponse.body);
          return {
            'success': true,
            'postId': publishData['id'],
          };
        }
      }
      
      throw Exception('Instagram post failed');
    } catch (e) {
      debugPrint('Instagram post error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Post to Twitter
  static Future<Map<String, dynamic>> _postToTwitter(
    String truckId,
    String text,
    String? imageUrl,
  ) async {
    try {
      final token = await storage.read(key: 'twitter_token_$truckId');
      if (token == null) throw Exception('Twitter not connected');
      
      final body = {
        'text': text,
      };
      
      // TODO: Handle image uploads for Twitter (requires media upload API)
      
      final response = await http.post(
        Uri.parse('https://api.twitter.com/2/tweets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'postId': data['data']['id'],
        };
      } else {
        throw Exception('Twitter post failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Twitter post error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Create automated opening post
  static Future<String> createOpeningPost({
    required String truckName,
    required String location,
    required String openTime,
    required String closeTime,
    List<String>? specialsToday,
  }) async {
    final buffer = StringBuffer();
    
    // Opening line with emoji
    buffer.writeln('🚚 $truckName is OPEN! 🎉');
    buffer.writeln();
    
    // Location
    buffer.writeln('📍 Location: $location');
    
    // Hours
    buffer.writeln('⏰ Hours: $openTime - $closeTime');
    buffer.writeln();
    
    // Specials if any
    if (specialsToday != null && specialsToday.isNotEmpty) {
      buffer.writeln("Today's Specials:");
      for (var special in specialsToday) {
        buffer.writeln('• $special');
      }
      buffer.writeln();
    }
    
    // Call to action
    buffer.writeln('See you soon! 😋');
    buffer.writeln();
    
    // Hashtags
    buffer.writeln('#FoodTruck #${truckName.replaceAll(' ', '')} #StreetFood #FoodTruckLife');
    
    return buffer.toString();
  }
}
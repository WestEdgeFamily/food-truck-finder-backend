import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'oauth_service.dart';
import 'api_service.dart';
import '../models/food_truck.dart';

/// Service to handle automated social media posting when truck opens
class AutomatedPostingService {
  static const _storage = FlutterSecureStorage();
  
  /// Check if truck is opening or closing now and post if needed
  static Future<void> checkAndPostScheduledMessages(String truckId) async {
    await checkAndPostOpeningMessage(truckId);
    await checkAndPostClosingMessage(truckId);
  }
  
  /// Check if truck is opening now and post if needed
  static Future<void> checkAndPostOpeningMessage(String truckId) async {
    try {
      // Check if automated posting is enabled
      final settingsJson = await _storage.read(key: 'automated_posting_settings_$truckId');
      if (settingsJson != null) {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        if (settings['enabled'] != true || settings['postOnOpen'] != true) {
          return; // Automated posting is disabled
        }
      } else {
        return; // No settings configured
      }
      
      debugPrint('🤖 Checking if truck $truckId is opening...');
      
      // Get truck details
      final truckData = await ApiService.getTruckById(truckId);
      if (truckData == null) {
        debugPrint('❌ Could not find truck data');
        return;
      }
      
      final truck = FoodTruck.fromJson(truckData);
      
      // Check if truck is scheduled to open now
      final now = DateTime.now();
      final dayOfWeek = _getDayOfWeek(now.weekday);
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // Get today's schedule
      final schedule = truck.schedule?[dayOfWeek];
      if (schedule == null || schedule['isOpen'] != true) {
        debugPrint('📅 Truck is not scheduled to be open today');
        return;
      }
      
      final openTime = schedule['openTime'] ?? '9:00';
      final closeTime = schedule['closeTime'] ?? '17:00';
      
      // Check if we're within 5 minutes of opening time
      if (_isWithinMinutes(currentTime, openTime, 5)) {
        // Check if we already posted today
        final todayKey = 'posted_opening_${truckId}_${now.year}-${now.month}-${now.day}';
        final alreadyPosted = await _storage.read(key: todayKey);
        if (alreadyPosted != null) {
          debugPrint('📌 Already posted opening message today');
          return;
        }
        
        debugPrint('🎉 Truck is opening! Time to post...');
        
        // Get current location
        String locationText = truck.address ?? 'Check our app for location';
        
        // Create opening message
        final message = await createOpeningMessage(
          truckName: truck.name,
          location: locationText,
          openTime: _formatTime(openTime),
          closeTime: _formatTime(closeTime),
          cuisine: truck.cuisineTypes.isNotEmpty ? truck.cuisineTypes.first : null,
          specialsToday: await _getTodaysSpecials(truckId),
          truckId: truckId,
        );
        
        // Post to all connected platforms
        final result = await postToAllConnectedPlatforms(
          truckId: truckId,
          message: message,
          imageUrl: truck.image,
        );
        
        // Mark as posted if successful
        if (result['success'] == true) {
          await _storage.write(key: todayKey, value: 'posted');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in automated posting: $e');
    }
  }
  
  /// Check if truck is closing now and post if needed
  static Future<void> checkAndPostClosingMessage(String truckId) async {
    try {
      // Check if automated posting is enabled
      final settingsJson = await _storage.read(key: 'automated_posting_settings_$truckId');
      if (settingsJson != null) {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        if (settings['enabled'] != true || settings['postOnClose'] != true) {
          return; // Automated posting is disabled
        }
      } else {
        return; // No settings configured
      }
      
      debugPrint('🤖 Checking if truck $truckId is closing...');
      
      // Get truck details
      final truckData = await ApiService.getTruckById(truckId);
      if (truckData == null) {
        debugPrint('❌ Could not find truck data');
        return;
      }
      
      final truck = FoodTruck.fromJson(truckData);
      
      // Check if truck is scheduled to close now
      final now = DateTime.now();
      final dayOfWeek = _getDayOfWeek(now.weekday);
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      // Get today's schedule
      final schedule = truck.schedule?[dayOfWeek];
      if (schedule == null || schedule['isOpen'] != true) {
        debugPrint('📅 Truck is not scheduled to be open today');
        return;
      }
      
      final closeTime = schedule['closeTime'];
      
      // Check if we're within 5 minutes of closing time
      if (_isWithinMinutes(currentTime, closeTime, 5)) {
        // Check if we already posted today
        final todayKey = 'posted_closing_${truckId}_${now.year}-${now.month}-${now.day}';
        final alreadyPosted = await _storage.read(key: todayKey);
        if (alreadyPosted != null) {
          debugPrint('📌 Already posted closing message today');
          return;
        }
        
        debugPrint('🌙 Truck is closing! Time to post...');
        
        // Get tomorrow's schedule
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowDayOfWeek = _getDayOfWeek(tomorrow.weekday);
        final tomorrowSchedule = truck.schedule?[tomorrowDayOfWeek];
        
        // Create closing message
        final message = await _createClosingMessage(
          truckName: truck.name,
          tomorrowSchedule: tomorrowSchedule,
          truckId: truckId,
        );
        
        // Post to all connected platforms
        final result = await postToAllConnectedPlatforms(
          truckId: truckId,
          message: message,
          imageUrl: truck.image,
        );
        
        // Mark as posted if successful
        if (result['success'] == true) {
          await _storage.write(key: todayKey, value: 'posted');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in automated closing post: $e');
    }
  }
  
  /// Post to all connected social media platforms
  static Future<Map<String, dynamic>> postToAllConnectedPlatforms({
    required String truckId,
    required String message,
    String? imageUrl,
  }) async {
    final results = <String, dynamic>{};
    
    try {
      // Get platform settings
      Map<String, bool> platformSettings = {
        'facebook': true,
        'instagram': true,
        'twitter': true,
        'linkedin': true,
        'tiktok': false,
      };
      
      final settingsJson = await _storage.read(key: 'automated_posting_settings_$truckId');
      if (settingsJson != null) {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        if (settings['platformSettings'] != null) {
          platformSettings = Map<String, bool>.from(settings['platformSettings']);
        }
      }
      
      // Get all connected accounts
      final accounts = await OAuthService.getAllStoredAccounts();
      
      for (final account in accounts) {
        final platform = account['platform'] as String;
        final tokens = account['tokens'] as Map<String, dynamic>;
        final accessToken = tokens['access_token'] as String?;
        
        if (accessToken == null) continue;
        
        // Check if platform is enabled in settings
        if (platformSettings[platform] != true) {
          debugPrint('⏭️ Skipping $platform (disabled in settings)');
          continue;
        }
        
        // Validate token is still valid
        final isValid = await OAuthService.validateToken(platform, accessToken);
        if (!isValid) {
          debugPrint('⚠️ Token expired for $platform, attempting refresh...');
          final refreshed = await OAuthService.refreshToken(platform);
          if (refreshed == null) {
            results[platform] = {'success': false, 'error': 'Token expired'};
            continue;
          }
        }
        
        // Post to platform
        switch (platform) {
          case 'facebook':
            results['facebook'] = await _postToFacebook(tokens, message, imageUrl);
            break;
          case 'instagram':
            if (imageUrl != null) {
              results['instagram'] = await _postToInstagram(tokens, message, imageUrl);
            } else {
              results['instagram'] = {'success': false, 'error': 'Instagram requires an image'};
            }
            break;
          case 'twitter':
            results['twitter'] = await _postToTwitter(tokens, message, imageUrl);
            break;
          case 'linkedin':
            results['linkedin'] = await _postToLinkedIn(tokens, message, imageUrl);
            break;
          case 'tiktok':
            if (imageUrl != null) {
              results['tiktok'] = await _postToTikTok(tokens, message, imageUrl);
            } else {
              results['tiktok'] = {'success': false, 'error': 'TikTok requires a video or image'};
            }
            break;
        }
      }
      
      // Log results
      debugPrint('📱 Automated posting results:');
      results.forEach((platform, result) {
        if (result['success'] == true) {
          debugPrint('✅ $platform: Posted successfully');
        } else {
          debugPrint('❌ $platform: ${result['error']}');
        }
      });
      
      return {
        'success': results.values.any((r) => r['success'] == true),
        'results': results,
        'message': 'Posted to ${results.values.where((r) => r['success'] == true).length} platforms',
      };
    } catch (e) {
      debugPrint('❌ Error posting to social media: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Post to Facebook
  static Future<Map<String, dynamic>> _postToFacebook(
    Map<String, dynamic> tokens,
    String message,
    String? imageUrl,
  ) async {
    try {
      final accessToken = tokens['access_token'];
      final userInfo = tokens['user_info'] as Map<String, dynamic>?;
      
      // Get Facebook pages
      final accounts = userInfo?['accounts']?['data'] as List?;
      if (accounts == null || accounts.isEmpty) {
        return {'success': false, 'error': 'No Facebook pages connected'};
      }
      
      // Post to first page (could be enhanced to let user choose)
      final page = accounts.first;
      final pageId = page['id'];
      final pageAccessToken = page['access_token'] ?? accessToken;
      
      final endpoint = imageUrl != null
          ? 'https://graph.facebook.com/v18.0/$pageId/photos'
          : 'https://graph.facebook.com/v18.0/$pageId/feed';
      
      final body = imageUrl != null
          ? {
              'message': message,
              'url': imageUrl,
              'access_token': pageAccessToken,
              'published': 'true',
            }
          : {
              'message': message,
              'access_token': pageAccessToken,
              'published': 'true',
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
          'platform': 'facebook',
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Facebook post failed');
      }
    } catch (e) {
      debugPrint('❌ Facebook post error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Post to Instagram
  static Future<Map<String, dynamic>> _postToInstagram(
    Map<String, dynamic> tokens,
    String caption,
    String imageUrl,
  ) async {
    try {
      final accessToken = tokens['access_token'];
      final userInfo = tokens['user_info'] as Map<String, dynamic>?;
      final userId = userInfo?['id'] ?? tokens['user_id'];
      
      if (userId == null) {
        return {'success': false, 'error': 'Instagram user ID not found'};
      }
      
      // For Instagram Business accounts via Facebook Graph API
      // First check if we have Instagram Business Account connected
      final fbUserInfo = tokens['user_info'] as Map<String, dynamic>?;
      final accounts = fbUserInfo?['accounts']?['data'] as List?;
      
      String? igBusinessAccountId;
      if (accounts != null) {
        for (final account in accounts) {
          if (account['instagram_business_account'] != null) {
            igBusinessAccountId = account['instagram_business_account']['id'];
            break;
          }
        }
      }
      
      if (igBusinessAccountId != null) {
        // Use Instagram Business API
        // Step 1: Create media container
        final createResponse = await http.post(
          Uri.parse('https://graph.facebook.com/v18.0/$igBusinessAccountId/media'),
          body: {
            'image_url': imageUrl,
            'caption': caption,
            'access_token': accessToken,
          },
        );
        
        if (createResponse.statusCode == 200) {
          final createData = jsonDecode(createResponse.body);
          final creationId = createData['id'];
          
          // Step 2: Wait a moment for processing
          await Future.delayed(const Duration(seconds: 2));
          
          // Step 3: Publish the media
          final publishResponse = await http.post(
            Uri.parse('https://graph.facebook.com/v18.0/$igBusinessAccountId/media_publish'),
            body: {
              'creation_id': creationId,
              'access_token': accessToken,
            },
          );
          
          if (publishResponse.statusCode == 200) {
            final publishData = jsonDecode(publishResponse.body);
            return {
              'success': true,
              'postId': publishData['id'],
              'platform': 'instagram',
            };
          }
        }
      }
      
      // Fallback for personal accounts (Basic Display API doesn't support posting)
      return {
        'success': false,
        'error': 'Instagram posting requires a Business account connected through Facebook',
      };
    } catch (e) {
      debugPrint('❌ Instagram post error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Post to Twitter
  static Future<Map<String, dynamic>> _postToTwitter(
    Map<String, dynamic> tokens,
    String text,
    String? imageUrl,
  ) async {
    try {
      final accessToken = tokens['access_token'];
      
      Map<String, dynamic> tweetData = {'text': text};
      
      // Handle image upload if provided
      if (imageUrl != null) {
        // First upload the image
        final mediaId = await _uploadTwitterMedia(accessToken, imageUrl);
        if (mediaId != null) {
          tweetData['media'] = {'media_ids': [mediaId]};
        }
      }
      
      final response = await http.post(
        Uri.parse('https://api.twitter.com/2/tweets'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(tweetData),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'postId': data['data']['id'],
          'platform': 'twitter',
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Twitter post failed');
      }
    } catch (e) {
      debugPrint('❌ Twitter post error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Upload media to Twitter
  static Future<String?> _uploadTwitterMedia(String accessToken, String imageUrl) async {
    try {
      // Download image first
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) return null;
      
      final imageBytes = imageResponse.bodyBytes;
      final base64Image = base64Encode(imageBytes);
      
      // Upload to Twitter
      final uploadResponse = await http.post(
        Uri.parse('https://upload.twitter.com/1.1/media/upload.json'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'media_data': base64Image,
          'media_category': 'tweet_image',
        },
      );
      
      if (uploadResponse.statusCode == 200) {
        final data = jsonDecode(uploadResponse.body);
        return data['media_id_string'];
      }
    } catch (e) {
      debugPrint('❌ Twitter media upload error: $e');
    }
    return null;
  }
  
  /// Post to LinkedIn
  static Future<Map<String, dynamic>> _postToLinkedIn(
    Map<String, dynamic> tokens,
    String text,
    String? imageUrl,
  ) async {
    try {
      final accessToken = tokens['access_token'];
      final userInfo = tokens['user_info'] as Map<String, dynamic>?;
      
      // Get person URN
      final personUrn = 'urn:li:person:${userInfo?['id']}';
      
      final postData = {
        'author': personUrn,
        'lifecycleState': 'PUBLISHED',
        'specificContent': {
          'com.linkedin.ugc.ShareContent': {
            'shareCommentary': {
              'text': text,
            },
            'shareMediaCategory': imageUrl != null ? 'IMAGE' : 'NONE',
            'media': imageUrl != null ? [
              {
                'status': 'READY',
                'description': {
                  'text': 'Food truck update',
                },
                'media': imageUrl,
                'title': {
                  'text': 'Food Truck',
                },
              }
            ] : [],
          },
        },
        'visibility': {
          'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC',
        },
      };
      
      final response = await http.post(
        Uri.parse('https://api.linkedin.com/v2/ugcPosts'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'X-Restli-Protocol-Version': '2.0.0',
        },
        body: jsonEncode(postData),
      );
      
      if (response.statusCode == 201) {
        final locationHeader = response.headers['x-restli-id'];
        return {
          'success': true,
          'postId': locationHeader,
          'platform': 'linkedin',
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'LinkedIn post failed');
      }
    } catch (e) {
      debugPrint('❌ LinkedIn post error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Post to TikTok
  static Future<Map<String, dynamic>> _postToTikTok(
    Map<String, dynamic> tokens,
    String caption,
    String mediaUrl,
  ) async {
    try {
      final accessToken = tokens['access_token'];
      
      // TikTok requires video content, not just images
      // For now, return an error for automated posting
      return {
        'success': false,
        'error': 'TikTok automated posting requires video content',
        'platform': 'tiktok',
      };
      
      // Future implementation would involve:
      // 1. Converting image to video with motion/effects
      // 2. Using TikTok's Content Posting API
      // 3. Handling video upload and publishing
    } catch (e) {
      debugPrint('❌ TikTok post error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Create opening message with emojis and formatting
  static Future<String> createOpeningMessage({
    required String truckName,
    required String location,
    required String openTime,
    required String closeTime,
    String? cuisine,
    List<String>? specialsToday,
    String? truckId,
  }) async {
    final buffer = StringBuffer();
    
    // Get settings if truckId is provided
    bool includeLocation = true;
    bool includeHours = true;
    bool includeSpecials = true;
    bool includeHashtags = true;
    List<String> customHashtags = [];
    
    if (truckId != null) {
      final settingsJson = await _storage.read(key: 'automated_posting_settings_$truckId');
      if (settingsJson != null) {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        includeLocation = settings['includeLocation'] ?? true;
        includeHours = settings['includeHours'] ?? true;
        includeSpecials = settings['includeSpecials'] ?? true;
        includeHashtags = settings['includeHashtags'] ?? true;
        customHashtags = List<String>.from(settings['customHashtags'] ?? []);
      }
    }
    
    // Opening line with emoji
    buffer.writeln('🚚 $truckName is OPEN! 🎉');
    buffer.writeln();
    
    // Location
    if (includeLocation) {
      buffer.writeln('📍 Location: $location');
    }
    
    // Hours
    if (includeHours) {
      buffer.writeln('⏰ Hours: $openTime - $closeTime');
    }
    
    // Cuisine type if available
    if (cuisine != null && cuisine.isNotEmpty) {
      buffer.writeln('🍴 Serving: $cuisine');
    }
    
    if (includeLocation || includeHours || (cuisine != null && cuisine.isNotEmpty)) {
      buffer.writeln();
    }
    
    // Today's specials if any
    if (includeSpecials && specialsToday != null && specialsToday.isNotEmpty) {
      buffer.writeln("🌟 Today's Specials:");
      for (var special in specialsToday) {
        buffer.writeln('  • $special');
      }
      buffer.writeln();
    }
    
    // Call to action
    buffer.writeln('Come hungry, leave happy! 😋');
    buffer.writeln();
    
    // Hashtags
    if (includeHashtags) {
      final truckHashtag = truckName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final cuisineHashtag = cuisine?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') ?? 'FoodTruck';
      buffer.write('#$truckHashtag #${cuisineHashtag}Food #StreetFood #FoodTruckLife #OpenNow');
      
      // Add custom hashtags
      for (final tag in customHashtags) {
        buffer.write(' #$tag');
      }
    }
    
    return buffer.toString();
  }
  
  /// Get today's specials from menu
  static Future<List<String>> _getTodaysSpecials(String truckId) async {
    try {
      // Get menu items
      final menuData = await ApiService.getMenuItems(truckId);
      final items = menuData['items'] as List? ?? [];
      
      // Filter for featured/special items
      final specials = items
          .where((item) => item['isFeatured'] == true || item['isSpecial'] == true)
          .take(3)
          .map((item) => '${item['name']} - \$${item['price']}')
          .toList();
      
      return specials;
    } catch (e) {
      debugPrint('Error getting specials: $e');
      return [];
    }
  }
  
  /// Check if current time is within X minutes of target time
  static bool _isWithinMinutes(String currentTime, String targetTime, int minutes) {
    try {
      final current = _parseTime(currentTime);
      final target = _parseTime(targetTime);
      
      final difference = (target.inMinutes - current.inMinutes).abs();
      return difference <= minutes;
    } catch (e) {
      return false;
    }
  }
  
  /// Parse time string to Duration
  static Duration _parseTime(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return Duration(hours: hours, minutes: minutes);
  }
  
  /// Format time for display
  static String _formatTime(String time) {
    try {
      final parts = time.split(':');
      var hours = int.parse(parts[0]);
      final minutes = parts[1];
      final period = hours >= 12 ? 'PM' : 'AM';
      
      if (hours > 12) hours -= 12;
      if (hours == 0) hours = 12;
      
      return '$hours:$minutes $period';
    } catch (e) {
      return time;
    }
  }
  
  /// Create closing message
  static Future<String> _createClosingMessage({
    required String truckName,
    Map<String, dynamic>? tomorrowSchedule,
    String? truckId,
  }) async {
    final buffer = StringBuffer();
    
    // Get settings if truckId is provided
    bool includeHashtags = true;
    List<String> customHashtags = [];
    
    if (truckId != null) {
      final settingsJson = await _storage.read(key: 'automated_posting_settings_$truckId');
      if (settingsJson != null) {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        includeHashtags = settings['includeHashtags'] ?? true;
        customHashtags = List<String>.from(settings['customHashtags'] ?? []);
      }
    }
    
    // Closing message
    buffer.writeln('🌙 $truckName is now CLOSED 🌙');
    buffer.writeln();
    buffer.writeln('Thank you for visiting us today! 🙏');
    buffer.writeln();
    
    // Tomorrow's schedule
    if (tomorrowSchedule != null && tomorrowSchedule['isOpen'] == true) {
      final openTime = _formatTime(tomorrowSchedule['openTime'] ?? '9:00');
      final closeTime = _formatTime(tomorrowSchedule['closeTime'] ?? '17:00');
      
      buffer.writeln('📅 See you tomorrow!');
      buffer.writeln('⏰ Hours: $openTime - $closeTime');
      buffer.writeln();
    } else {
      buffer.writeln('📅 Check our app for our next opening date!');
      buffer.writeln();
    }
    
    buffer.writeln('Sweet dreams and food truck dreams! 🚚💤');
    
    // Hashtags
    if (includeHashtags) {
      buffer.writeln();
      final truckHashtag = truckName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      buffer.write('#$truckHashtag #FoodTruck #ClosedForToday #SeeYouTomorrow');
      
      // Add custom hashtags
      for (final tag in customHashtags) {
        buffer.write(' #$tag');
      }
    }
    
    return buffer.toString();
  }
  
  /// Get day of week name
  static String _getDayOfWeek(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
}
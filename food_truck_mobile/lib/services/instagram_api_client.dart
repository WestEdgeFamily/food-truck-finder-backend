import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'oauth_service.dart';

class InstagramApiClient {
  static const String _baseUrl = 'https://graph.instagram.com';
  static const String _apiVersion = 'v18.0';

  // Get user profile information
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        throw Exception('No Instagram access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/me?fields=id,username,account_type,media_count&access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Instagram API error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting Instagram user profile: $e');
      return null;
    }
  }

  // Get user's media
  static Future<List<Map<String, dynamic>>> getUserMedia({
    int limit = 25,
    String? after,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        throw Exception('No Instagram access token found');
      }

      final accessToken = tokens['access_token'];
      var url = '$_baseUrl/me/media?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp&limit=$limit&access_token=$accessToken';
      
      if (after != null) {
        url += '&after=$after';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('❌ Instagram API error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting Instagram user media: $e');
      return [];
    }
  }

  // Create media object (for posting)
  static Future<String?> createMediaObject({
    required String imageUrl,
    String? caption,
    List<String>? hashtags,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        throw Exception('No Instagram access token found');
      }

      final accessToken = tokens['access_token'];
      final userId = tokens['user_id'];

      // Prepare caption with hashtags
      String finalCaption = caption ?? '';
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        finalCaption = finalCaption.isNotEmpty 
          ? '$finalCaption\n\n$hashtagString'
          : hashtagString;
      }

      final body = {
        'image_url': imageUrl,
        'access_token': accessToken,
        if (finalCaption.isNotEmpty) 'caption': finalCaption,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/$userId/media'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id']; // Returns the media container ID
      } else {
        debugPrint('❌ Instagram create media error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating Instagram media object: $e');
      return null;
    }
  }

  // Publish media object
  static Future<Map<String, dynamic>?> publishMedia(String creationId) async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        throw Exception('No Instagram access token found');
      }

      final accessToken = tokens['access_token'];
      final userId = tokens['user_id'];

      final response = await http.post(
        Uri.parse('$_baseUrl/$userId/media_publish'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'creation_id': creationId,
          'access_token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Instagram publish media error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error publishing Instagram media: $e');
      return null;
    }
  }

  // Post image to Instagram (combines create and publish)
  static Future<Map<String, dynamic>?> postImage({
    required String imageUrl,
    String? caption,
    List<String>? hashtags,
  }) async {
    try {
      debugPrint('📸 Creating Instagram media object...');
      final creationId = await createMediaObject(
        imageUrl: imageUrl,
        caption: caption,
        hashtags: hashtags,
      );

      if (creationId == null) {
        throw Exception('Failed to create media object');
      }

      debugPrint('📸 Publishing Instagram media...');
      final result = await publishMedia(creationId);

      if (result != null) {
        debugPrint('✅ Instagram post published successfully: ${result['id']}');
        return result;
      } else {
        throw Exception('Failed to publish media');
      }
    } catch (e) {
      debugPrint('❌ Error posting to Instagram: $e');
      return null;
    }
  }

  // Upload image to a temporary hosting service (needed for Instagram API)
  static Future<String?> uploadImageToHost(File imageFile) async {
    try {
      // For production, you would upload to your own server or a service like Cloudinary
      // For now, we'll simulate this or use a temporary hosting service
      
      debugPrint('📤 Uploading image to temporary host...');
      
      // This is a placeholder - in production you'd implement actual image upload
      // to your backend server or a service like Cloudinary, AWS S3, etc.
      
      // For demonstration, we'll return a placeholder URL
      // In real implementation, you would:
      // 1. Upload the file to your server
      // 2. Return the public URL
      
      throw UnimplementedError(
        'Image upload to hosting service not implemented. '
        'Please implement uploadImageToHost() to upload images to your server.'
      );
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  // Get media insights (analytics)
  static Future<Map<String, dynamic>?> getMediaInsights(String mediaId) async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        throw Exception('No Instagram access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/$mediaId/insights?metric=impressions,reach,engagement&access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Instagram insights error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting Instagram media insights: $e');
      return null;
    }
  }

  // Get account insights
  static Future<Map<String, dynamic>?> getAccountInsights({
    String period = 'day',
    required DateTime since,
    required DateTime until,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        throw Exception('No Instagram access token found');
      }

      final accessToken = tokens['access_token'];
      final userId = tokens['user_id'];

      final sinceTimestamp = (since.millisecondsSinceEpoch / 1000).round();
      final untilTimestamp = (until.millisecondsSinceEpoch / 1000).round();

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/$userId/insights?metric=impressions,reach,profile_views&period=$period&since=$sinceTimestamp&until=$untilTimestamp&access_token=$accessToken'
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Instagram account insights error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting Instagram account insights: $e');
      return null;
    }
  }

  // Validate access token
  static Future<bool> validateAccessToken() async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        return false;
      }

      final accessToken = tokens['access_token'];
      return await OAuthService.validateToken('instagram', accessToken);
    } catch (e) {
      debugPrint('❌ Error validating Instagram access token: $e');
      return false;
    }
  }

  // Get hashtag information
  static Future<Map<String, dynamic>?> getHashtagInfo(String hashtag) async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        throw Exception('No Instagram access token found');
      }

      final accessToken = tokens['access_token'];
      final userId = tokens['user_id'];

      // First, search for the hashtag ID
      final searchResponse = await http.get(
        Uri.parse('$_baseUrl/ig_hashtag_search?user_id=$userId&q=$hashtag&access_token=$accessToken'),
      );

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final hashtags = searchData['data'] as List?;
        
        if (hashtags != null && hashtags.isNotEmpty) {
          final hashtagId = hashtags.first['id'];
          
          // Get hashtag info
          final infoResponse = await http.get(
            Uri.parse('$_baseUrl/$hashtagId?fields=id,name&access_token=$accessToken'),
          );

          if (infoResponse.statusCode == 200) {
            return json.decode(infoResponse.body);
          }
        }
      }

      debugPrint('❌ Instagram hashtag search error: ${searchResponse.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting Instagram hashtag info: $e');
      return null;
    }
  }

  // Refresh access token
  static Future<bool> refreshAccessToken() async {
    try {
      final tokens = await OAuthService.getStoredTokens('instagram');
      if (tokens == null) {
        return false;
      }

      final refreshToken = tokens['refresh_token'];
      if (refreshToken == null) {
        return false;
      }

      final newTokens = await OAuthService.refreshInstagramToken(refreshToken);
      return newTokens != null;
    } catch (e) {
      debugPrint('❌ Error refreshing Instagram access token: $e');
      return false;
    }
  }
} 
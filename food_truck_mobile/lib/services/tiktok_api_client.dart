import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'oauth_service.dart';

class TikTokApiClient {
  static const String _baseUrl = 'https://open-api.tiktok.com';

  // Get user info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.post(
        Uri.parse('$_baseUrl/user/info/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'access_token': accessToken,
          'fields': [
            'open_id',
            'union_id',
            'avatar_url',
            'avatar_url_100',
            'avatar_large_url',
            'display_name',
            'bio_description',
            'profile_deep_link',
            'is_verified',
            'follower_count',
            'following_count',
            'likes_count',
            'video_count'
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error']['code'] == 'ok') {
          return data['data']['user'];
        } else {
          debugPrint('❌ TikTok API error: ${data['error']['message']}');
          return null;
        }
      } else {
        debugPrint('❌ TikTok API error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting TikTok user info: $e');
      return null;
    }
  }

  // Upload video to TikTok
  static Future<Map<String, dynamic>?> uploadVideo({
    required File videoFile,
    required String title,
    String? description,
    List<String>? hashtags,
    bool disableComment = false,
    bool disableDuet = false,
    bool disableStitch = false,
    String privacyLevel = 'MUTUAL_FOLLOW_FRIEND', // PUBLIC_TO_EVERYONE, MUTUAL_FOLLOW_FRIEND, FOLLOWER_OF_CREATOR, SELF_ONLY
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      // Prepare description with hashtags
      String finalDescription = description ?? '';
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        finalDescription = finalDescription.isNotEmpty 
          ? '$finalDescription\n\n$hashtagString'
          : hashtagString;
      }

      final accessToken = tokens['access_token'];

      // Step 1: Initialize upload
      final initBody = {
        'post_info': {
          'title': title,
          'description': finalDescription,
          'disable_comment': disableComment,
          'disable_duet': disableDuet,
          'disable_stitch': disableStitch,
          'privacy_level': privacyLevel,
        },
        'source_info': {
          'source': 'FILE_UPLOAD',
        }
      };

      final initResponse = await http.post(
        Uri.parse('$_baseUrl/post/publish/inbox/video/init/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(initBody),
      );

      if (initResponse.statusCode != 200) {
        debugPrint('❌ TikTok upload init error: ${initResponse.body}');
        return null;
      }

      final initData = json.decode(initResponse.body);
      if (initData['error']['code'] != 'ok') {
        debugPrint('❌ TikTok upload init error: ${initData['error']['message']}');
        return null;
      }

      final publishId = initData['data']['publish_id'];
      final uploadUrl = initData['data']['upload_url'];

      // Step 2: Upload video file
      final videoBytes = await videoFile.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': 'video/mp4',
          'Content-Length': videoBytes.length.toString(),
        },
        body: videoBytes,
      );

      if (uploadResponse.statusCode != 200) {
        debugPrint('❌ TikTok video upload error: ${uploadResponse.statusCode}');
        return null;
      }

      // Step 3: Confirm upload
      final confirmBody = {
        'publish_id': publishId,
      };

      final confirmResponse = await http.post(
        Uri.parse('$_baseUrl/post/publish/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(confirmBody),
      );

      if (confirmResponse.statusCode == 200) {
        final confirmData = json.decode(confirmResponse.body);
        if (confirmData['error']['code'] == 'ok') {
          debugPrint('✅ TikTok video uploaded successfully');
          return confirmData['data'];
        } else {
          debugPrint('❌ TikTok upload confirm error: ${confirmData['error']['message']}');
          return null;
        }
      } else {
        debugPrint('❌ TikTok upload confirm error: ${confirmResponse.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading video to TikTok: $e');
      return null;
    }
  }

  // Get user's videos
  static Future<List<Map<String, dynamic>>> getUserVideos({
    int maxCount = 20,
    String? cursor,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      final accessToken = tokens['access_token'];
      final body = <String, dynamic>{
        'access_token': accessToken,
        'fields': [
          'id',
          'title',
          'video_description',
          'duration',
          'cover_image_url',
          'share_url',
          'embed_html',
          'embed_link',
          'like_count',
          'comment_count',
          'share_count',
          'view_count',
        ],
        'max_count': maxCount,
      };

      if (cursor != null) {
        body['cursor'] = cursor;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/video/list/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error']['code'] == 'ok') {
          return List<Map<String, dynamic>>.from(data['data']['videos'] ?? []);
        } else {
          debugPrint('❌ TikTok videos API error: ${data['error']['message']}');
          return [];
        }
      } else {
        debugPrint('❌ TikTok videos API error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting TikTok user videos: $e');
      return [];
    }
  }

  // Get video analytics
  static Future<Map<String, dynamic>?> getVideoAnalytics({
    required String videoId,
    required List<String> metrics,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      final accessToken = tokens['access_token'];
      final body = {
        'access_token': accessToken,
        'video_ids': [videoId],
        'metrics': metrics, // ['PROFILE_VIEW', 'LIKES', 'COMMENTS', 'SHARES', 'REACH', 'VIDEO_VIEWS']
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/business/get/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error']['code'] == 'ok') {
          return data['data'];
        } else {
          debugPrint('❌ TikTok analytics error: ${data['error']['message']}');
          return null;
        }
      } else {
        debugPrint('❌ TikTok analytics error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting TikTok video analytics: $e');
      return null;
    }
  }

  // Get account analytics
  static Future<Map<String, dynamic>?> getAccountAnalytics({
    required List<String> metrics,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      final accessToken = tokens['access_token'];
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final body = {
        'access_token': accessToken,
        'metrics': metrics, // ['PROFILE_VIEW', 'LIKES', 'COMMENTS', 'SHARES', 'REACH', 'VIDEO_VIEWS']
        'start_date': startDateStr,
        'end_date': endDateStr,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/business/get/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error']['code'] == 'ok') {
          return data['data'];
        } else {
          debugPrint('❌ TikTok account analytics error: ${data['error']['message']}');
          return null;
        }
      } else {
        debugPrint('❌ TikTok account analytics error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting TikTok account analytics: $e');
      return null;
    }
  }

  // Get video comments
  static Future<List<Map<String, dynamic>>> getVideoComments({
    required String videoId,
    int maxCount = 50,
    String? cursor,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      final accessToken = tokens['access_token'];
      final body = <String, dynamic>{
        'access_token': accessToken,
        'video_id': videoId,
        'max_count': maxCount,
      };

      if (cursor != null) {
        body['cursor'] = cursor;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/comment/list/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error']['code'] == 'ok') {
          return List<Map<String, dynamic>>.from(data['data']['comments'] ?? []);
        } else {
          debugPrint('❌ TikTok comments error: ${data['error']['message']}');
          return [];
        }
      } else {
        debugPrint('❌ TikTok comments error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting TikTok video comments: $e');
      return [];
    }
  }

  // Reply to comment
  static Future<bool> replyToComment({
    required String videoId,
    required String commentId,
    required String text,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      final accessToken = tokens['access_token'];
      final body = {
        'access_token': accessToken,
        'video_id': videoId,
        'comment_id': commentId,
        'text': text,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/comment/reply/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['error']['code'] == 'ok';
      } else {
        debugPrint('❌ TikTok reply error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error replying to TikTok comment: $e');
      return false;
    }
  }

  // Check video upload status
  static Future<Map<String, dynamic>?> checkUploadStatus(String publishId) async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      final accessToken = tokens['access_token'];
      final body = {
        'access_token': accessToken,
        'publish_ids': [publishId],
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/post/publish/status/fetch/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error']['code'] == 'ok') {
          final statuses = data['data']['publish_status_list'] as List?;
          if (statuses != null && statuses.isNotEmpty) {
            return statuses.first;
          }
        } else {
          debugPrint('❌ TikTok status check error: ${data['error']['message']}');
        }
      } else {
        debugPrint('❌ TikTok status check error: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error checking TikTok upload status: $e');
      return null;
    }
  }

  // Validate access token
  static Future<bool> validateAccessToken() async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        return false;
      }

      final accessToken = tokens['access_token'];
      return await OAuthService.validateToken('tiktok', accessToken);
    } catch (e) {
      debugPrint('❌ Error validating TikTok access token: $e');
      return false;
    }
  }

  // Refresh access token
  static Future<bool> refreshAccessToken() async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        return false;
      }

      final refreshToken = tokens['refresh_token'];
      if (refreshToken == null) {
        return false;
      }

      final newTokens = await OAuthService.refreshToken('tiktok');
      return newTokens != null;
    } catch (e) {
      debugPrint('❌ Error refreshing TikTok access token: $e');
      return false;
    }
  }

  // Get trending hashtags
  static Future<List<String>> getTrendingHashtags() async {
    try {
      final tokens = await OAuthService.getStoredTokens('tiktok');
      if (tokens == null) {
        throw Exception('No TikTok access token found');
      }

      final accessToken = tokens['access_token'];
      final body = {
        'access_token': accessToken,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/research/hashtag/trending/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error']['code'] == 'ok') {
          final hashtags = data['data']['hashtags'] as List?;
          if (hashtags != null) {
            return hashtags.map((h) => h['hashtag_name'] as String).toList();
          }
        } else {
          debugPrint('❌ TikTok trending hashtags error: ${data['error']['message']}');
        }
      } else {
        debugPrint('❌ TikTok trending hashtags error: ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting TikTok trending hashtags: $e');
      return [];
    }
  }

  // Upload short video (optimized for food truck content)
  static Future<Map<String, dynamic>?> uploadFoodTruckVideo({
    required File videoFile,
    required String title,
    String? description,
    List<String>? foodHashtags,
    String? location,
  }) async {
    try {
      // Food truck specific hashtags
      final defaultFoodHashtags = [
        'foodtruck',
        'streetfood',
        'foodie',
        'delicious',
        'yummy',
        'fresh',
        'local',
        'foodlover'
      ];

      final combinedHashtags = <String>{
        ...defaultFoodHashtags,
        if (foodHashtags != null) ...foodHashtags,
      }.toList();

      String finalDescription = description ?? '';
      if (location != null) {
        finalDescription = finalDescription.isNotEmpty 
          ? '$finalDescription\n📍 $location'
          : '📍 $location';
      }

      return await uploadVideo(
        videoFile: videoFile,
        title: title,
        description: finalDescription,
        hashtags: combinedHashtags,
        privacyLevel: 'PUBLIC_TO_EVERYONE', // Food trucks want maximum visibility
      );
    } catch (e) {
      debugPrint('❌ Error uploading food truck video to TikTok: $e');
      return null;
    }
  }
} 
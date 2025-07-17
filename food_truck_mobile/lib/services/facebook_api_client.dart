import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'oauth_service.dart';

class FacebookApiClient {
  static const String _baseUrl = 'https://graph.facebook.com';
  static const String _apiVersion = 'v18.0';

  // Get user profile and pages
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final tokens = await OAuthService.getStoredTokens('facebook');
      if (tokens == null) {
        throw Exception('No Facebook access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/me?fields=id,name,email,accounts{id,name,access_token,fan_count,category,picture}&access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Facebook API error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting Facebook user profile: $e');
      return null;
    }
  }

  // Get user's Facebook pages
  static Future<List<Map<String, dynamic>>> getUserPages() async {
    try {
      final tokens = await OAuthService.getStoredTokens('facebook');
      if (tokens == null) {
        throw Exception('No Facebook access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/me/accounts?fields=id,name,access_token,fan_count,category,picture,instagram_business_account&access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('❌ Facebook pages API error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting Facebook pages: $e');
      return [];
    }
  }

  // Post to Facebook page
  static Future<Map<String, dynamic>?> postToPage({
    required String pageId,
    required String pageAccessToken,
    String? message,
    String? imageUrl,
    String? link,
    List<String>? hashtags,
  }) async {
    try {
      // Prepare message with hashtags
      String finalMessage = message ?? '';
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        finalMessage = finalMessage.isNotEmpty 
          ? '$finalMessage\n\n$hashtagString'
          : hashtagString;
      }

      final body = <String, String>{
        'access_token': pageAccessToken,
      };

      if (finalMessage.isNotEmpty) {
        body['message'] = finalMessage;
      }

      if (imageUrl != null) {
        body['url'] = imageUrl;
      }

      if (link != null) {
        body['link'] = link;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$pageId/photos'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Facebook post error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error posting to Facebook page: $e');
      return null;
    }
  }

  // Post text-only to Facebook page
  static Future<Map<String, dynamic>?> postTextToPage({
    required String pageId,
    required String pageAccessToken,
    required String message,
    List<String>? hashtags,
    String? link,
  }) async {
    try {
      // Prepare message with hashtags
      String finalMessage = message;
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        finalMessage = '$finalMessage\n\n$hashtagString';
      }

      final body = <String, String>{
        'message': finalMessage,
        'access_token': pageAccessToken,
      };

      if (link != null) {
        body['link'] = link;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$pageId/feed'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Facebook text post error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error posting text to Facebook page: $e');
      return null;
    }
  }

  // Upload image to Facebook and get URL
  static Future<String?> uploadImage({
    required String pageId,
    required String pageAccessToken,
    required File imageFile,
    bool published = false,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/$pageId/photos'),
      );

      request.fields['access_token'] = pageAccessToken;
      request.fields['published'] = published.toString();

      final multipartFile = await http.MultipartFile.fromPath(
        'source',
        imageFile.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        debugPrint('❌ Facebook image upload error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading image to Facebook: $e');
      return null;
    }
  }

  // Get page posts
  static Future<List<Map<String, dynamic>>> getPagePosts({
    required String pageId,
    required String pageAccessToken,
    int limit = 25,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$pageId/posts?fields=id,message,created_time,picture,full_picture,permalink_url,insights.metric(post_impressions,post_engaged_users)&limit=$limit&access_token=$pageAccessToken'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('❌ Facebook posts API error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting Facebook page posts: $e');
      return [];
    }
  }

  // Get page insights
  static Future<Map<String, dynamic>?> getPageInsights({
    required String pageId,
    required String pageAccessToken,
    required DateTime since,
    required DateTime until,
  }) async {
    try {
      final sinceFormatted = since.toIso8601String().split('T')[0];
      final untilFormatted = until.toIso8601String().split('T')[0];

      final response = await http.get(
        Uri.parse('$_baseUrl/$pageId/insights?metric=page_impressions,page_engaged_users,page_post_engagements,page_fans&since=$sinceFormatted&until=$untilFormatted&period=day&access_token=$pageAccessToken'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Facebook insights error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting Facebook page insights: $e');
      return null;
    }
  }

  // Get post insights
  static Future<Map<String, dynamic>?> getPostInsights({
    required String postId,
    required String pageAccessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$postId/insights?metric=post_impressions,post_clicks,post_reactions_by_type_total&access_token=$pageAccessToken'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Facebook post insights error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting Facebook post insights: $e');
      return null;
    }
  }

  // Schedule a post
  static Future<Map<String, dynamic>?> schedulePost({
    required String pageId,
    required String pageAccessToken,
    required String message,
    required DateTime scheduledTime,
    String? imageUrl,
    List<String>? hashtags,
  }) async {
    try {
      // Prepare message with hashtags
      String finalMessage = message;
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        finalMessage = '$finalMessage\n\n$hashtagString';
      }

      final scheduledTimestamp = (scheduledTime.millisecondsSinceEpoch / 1000).round();

      final body = <String, String>{
        'message': finalMessage,
        'scheduled_publish_time': scheduledTimestamp.toString(),
        'published': 'false',
        'access_token': pageAccessToken,
      };

      if (imageUrl != null) {
        body['url'] = imageUrl;
      }

      final endpoint = imageUrl != null ? 'photos' : 'feed';
      final response = await http.post(
        Uri.parse('$_baseUrl/$pageId/$endpoint'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Facebook schedule post error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error scheduling Facebook post: $e');
      return null;
    }
  }

  // Get scheduled posts
  static Future<List<Map<String, dynamic>>> getScheduledPosts({
    required String pageId,
    required String pageAccessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$pageId/scheduled_posts?fields=id,message,scheduled_publish_time,created_time&access_token=$pageAccessToken'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('❌ Facebook scheduled posts error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting Facebook scheduled posts: $e');
      return [];
    }
  }

  // Delete a post
  static Future<bool> deletePost({
    required String postId,
    required String pageAccessToken,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$postId?access_token=$pageAccessToken'),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting Facebook post: $e');
      return false;
    }
  }

  // Get connected Instagram account for a page
  static Future<Map<String, dynamic>?> getConnectedInstagramAccount({
    required String pageId,
    required String pageAccessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$pageId/instagram_accounts?access_token=$pageAccessToken'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accounts = data['data'] as List?;
        return accounts?.isNotEmpty == true ? accounts!.first : null;
      } else {
        debugPrint('❌ Facebook Instagram account error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting connected Instagram account: $e');
      return null;
    }
  }

  // Validate access token
  static Future<bool> validateAccessToken() async {
    try {
      final tokens = await OAuthService.getStoredTokens('facebook');
      if (tokens == null) {
        return false;
      }

      final accessToken = tokens['access_token'];
      return await OAuthService.validateToken('facebook', accessToken);
    } catch (e) {
      debugPrint('❌ Error validating Facebook access token: $e');
      return false;
    }
  }

  // Get page access token for a specific page
  static Future<String?> getPageAccessToken(String pageId) async {
    try {
      final pages = await getUserPages();
      for (final page in pages) {
        if (page['id'] == pageId) {
          return page['access_token'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting page access token: $e');
      return null;
    }
  }

  // Get page info
  static Future<Map<String, dynamic>?> getPageInfo(String pageId, String pageAccessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$pageId?fields=id,name,fan_count,category,picture,about,website&access_token=$pageAccessToken'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Facebook page info error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting Facebook page info: $e');
      return null;
    }
  }
} 
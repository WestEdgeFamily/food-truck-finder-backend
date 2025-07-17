import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'oauth_service.dart';

class TwitterApiClient {
  static const String _baseUrl = 'https://api.twitter.com/2';
  static const String _uploadUrl = 'https://upload.twitter.com/1.1';

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me?user.fields=id,name,username,description,public_metrics,profile_image_url,verified'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        debugPrint('❌ Twitter API error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting Twitter user profile: $e');
      return null;
    }
  }

  // Post a tweet
  static Future<Map<String, dynamic>?> postTweet({
    required String text,
    List<String>? mediaIds,
    List<String>? hashtags,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      // Prepare text with hashtags
      String finalText = text;
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        // Check Twitter character limit (280)
        if (('$finalText\n\n$hashtagString').length <= 280) {
          finalText = '$finalText\n\n$hashtagString';
        } else if (hashtagString.length <= 280) {
          finalText = hashtagString;
        }
      }

      final accessToken = tokens['access_token'];
      final body = <String, dynamic>{
        'text': finalText,
      };

      if (mediaIds != null && mediaIds.isNotEmpty) {
        body['media'] = {
          'media_ids': mediaIds,
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/tweets'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Twitter post error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error posting tweet: $e');
      return null;
    }
  }

  // Upload media (image/video)
  static Future<String?> uploadMedia(File mediaFile) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      
      // Step 1: Initialize upload
      final fileBytes = await mediaFile.readAsBytes();
      final initResponse = await http.post(
        Uri.parse('$_uploadUrl/media/upload.json'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'command': 'INIT',
          'total_bytes': fileBytes.length.toString(),
          'media_type': _getMediaType(mediaFile.path),
        },
      );

      if (initResponse.statusCode != 202) {
        debugPrint('❌ Twitter media init error: ${initResponse.body}');
        return null;
      }

      final initData = json.decode(initResponse.body);
      final mediaId = initData['media_id_string'];

      // Step 2: Upload media chunks
      const chunkSize = 5 * 1024 * 1024; // 5MB chunks
      int segmentIndex = 0;

      for (int i = 0; i < fileBytes.length; i += chunkSize) {
        final end = (i + chunkSize < fileBytes.length) ? i + chunkSize : fileBytes.length;
        final chunk = fileBytes.sublist(i, end);

        final appendResponse = await http.post(
          Uri.parse('$_uploadUrl/media/upload.json'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
          body: {
            'command': 'APPEND',
            'media_id': mediaId,
            'segment_index': segmentIndex.toString(),
            'media': base64Encode(chunk),
          },
        );

        if (appendResponse.statusCode != 204) {
          debugPrint('❌ Twitter media append error: ${appendResponse.body}');
          return null;
        }

        segmentIndex++;
      }

      // Step 3: Finalize upload
      final finalizeResponse = await http.post(
        Uri.parse('$_uploadUrl/media/upload.json'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'command': 'FINALIZE',
          'media_id': mediaId,
        },
      );

      if (finalizeResponse.statusCode == 201) {
        return mediaId;
      } else {
        debugPrint('❌ Twitter media finalize error: ${finalizeResponse.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading media to Twitter: $e');
      return null;
    }
  }

  // Get user's tweets
  static Future<List<Map<String, dynamic>>> getUserTweets({
    String? userId,
    int maxResults = 10,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final userIdToUse = userId ?? tokens['user_info']['id'];

      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userIdToUse/tweets?tweet.fields=id,text,created_at,public_metrics,attachments&max_results=$maxResults'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('❌ Twitter user tweets error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting user tweets: $e');
      return [];
    }
  }

  // Get tweet by ID
  static Future<Map<String, dynamic>?> getTweet(String tweetId) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/tweets/$tweetId?tweet.fields=id,text,created_at,public_metrics,attachments&expansions=author_id'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        debugPrint('❌ Twitter get tweet error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting tweet: $e');
      return null;
    }
  }

  // Delete a tweet
  static Future<bool> deleteTweet(String tweetId) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.delete(
        Uri.parse('$_baseUrl/tweets/$tweetId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting tweet: $e');
      return false;
    }
  }

  // Like a tweet
  static Future<bool> likeTweet(String tweetId) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final userId = tokens['user_info']['id'];

      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/likes'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tweet_id': tweetId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error liking tweet: $e');
      return false;
    }
  }

  // Retweet a tweet
  static Future<bool> retweet(String tweetId) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final userId = tokens['user_info']['id'];

      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/retweets'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tweet_id': tweetId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error retweeting: $e');
      return false;
    }
  }

  // Search tweets
  static Future<List<Map<String, dynamic>>> searchTweets({
    required String query,
    int maxResults = 10,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final encodedQuery = Uri.encodeComponent(query);

      final response = await http.get(
        Uri.parse('$_baseUrl/tweets/search/recent?query=$encodedQuery&tweet.fields=id,text,created_at,public_metrics&max_results=$maxResults'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('❌ Twitter search error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error searching tweets: $e');
      return [];
    }
  }

  // Get followers
  static Future<List<Map<String, dynamic>>> getFollowers({
    String? userId,
    int maxResults = 100,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final userIdToUse = userId ?? tokens['user_info']['id'];

      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userIdToUse/followers?user.fields=id,name,username,public_metrics&max_results=$maxResults'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('❌ Twitter followers error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting followers: $e');
      return [];
    }
  }

  // Get following
  static Future<List<Map<String, dynamic>>> getFollowing({
    String? userId,
    int maxResults = 100,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        throw Exception('No Twitter access token found');
      }

      final accessToken = tokens['access_token'];
      final userIdToUse = userId ?? tokens['user_info']['id'];

      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userIdToUse/following?user.fields=id,name,username,public_metrics&max_results=$maxResults'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('❌ Twitter following error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting following: $e');
      return [];
    }
  }

  // Post tweet with image
  static Future<Map<String, dynamic>?> postTweetWithImage({
    required String text,
    required File imageFile,
    List<String>? hashtags,
  }) async {
    try {
      debugPrint('📤 Uploading image to Twitter...');
      final mediaId = await uploadMedia(imageFile);
      
      if (mediaId == null) {
        throw Exception('Failed to upload image');
      }

      debugPrint('📝 Posting tweet with image...');
      final result = await postTweet(
        text: text,
        mediaIds: [mediaId],
        hashtags: hashtags,
      );

      if (result != null) {
        debugPrint('✅ Tweet posted successfully: ${result['data']['id']}');
        return result;
      } else {
        throw Exception('Failed to post tweet');
      }
    } catch (e) {
      debugPrint('❌ Error posting tweet with image: $e');
      return null;
    }
  }

  // Validate access token
  static Future<bool> validateAccessToken() async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        return false;
      }

      final accessToken = tokens['access_token'];
      return await OAuthService.validateToken('twitter', accessToken);
    } catch (e) {
      debugPrint('❌ Error validating Twitter access token: $e');
      return false;
    }
  }

  // Get media type from file extension
  static String _getMediaType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'image/jpeg';
    }
  }

  // Refresh access token
  static Future<bool> refreshAccessToken() async {
    try {
      final tokens = await OAuthService.getStoredTokens('twitter');
      if (tokens == null) {
        return false;
      }

      final refreshToken = tokens['refresh_token'];
      if (refreshToken == null) {
        return false;
      }

      final newTokens = await OAuthService.refreshToken('twitter');
      return newTokens != null;
    } catch (e) {
      debugPrint('❌ Error refreshing Twitter access token: $e');
      return false;
    }
  }
} 
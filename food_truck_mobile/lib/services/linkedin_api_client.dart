import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'oauth_service.dart';

class LinkedInApiClient {
  static const String _baseUrl = 'https://api.linkedin.com/v2';

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/people/~?projection=(id,firstName,lastName,headline,profilePicture(displayImage~:playableStreams))'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ LinkedIn API error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting LinkedIn user profile: $e');
      return null;
    }
  }

  // Get user's email address
  static Future<String?> getUserEmail() async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/emailAddress?q=members&projection=(elements*(handle~))'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List?;
        if (elements != null && elements.isNotEmpty) {
          return elements.first['handle~']['emailAddress'];
        }
      } else {
        debugPrint('❌ LinkedIn email API error: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting LinkedIn user email: $e');
      return null;
    }
  }

  // Get company pages managed by user
  static Future<List<Map<String, dynamic>>> getCompanyPages() async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.get(
        Uri.parse('$_baseUrl/organizationalEntityAcls?q=roleAssignee&projection=(elements*(organizationalTarget~(id,name,vanityName,logoV2(original~:playableStreams))))'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List?;
        if (elements != null) {
          return elements
              .map((element) => element['organizationalTarget~'] as Map<String, dynamic>)
              .toList();
        }
      } else {
        debugPrint('❌ LinkedIn company pages API error: ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting LinkedIn company pages: $e');
      return [];
    }
  }

  // Post to LinkedIn (personal profile)
  static Future<Map<String, dynamic>?> postToProfile({
    required String text,
    String? imageUrl,
    String? articleUrl,
    String? articleTitle,
    String? articleDescription,
    List<String>? hashtags,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      // Get user ID
      final profile = await getUserProfile();
      if (profile == null) {
        throw Exception('Could not get user profile');
      }

      final personId = profile['id'];
      final accessToken = tokens['access_token'];

      // Prepare text with hashtags
      String finalText = text;
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        finalText = '$finalText\n\n$hashtagString';
      }

      final body = <String, dynamic>{
        'author': 'urn:li:person:$personId',
        'lifecycleState': 'PUBLISHED',
        'specificContent': {
          'com.linkedin.ugc.ShareContent': {
            'shareCommentary': {
              'text': finalText,
            },
            'shareMediaCategory': 'NONE',
          },
        },
        'visibility': {
          'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC',
        },
      };

      // Add media if provided
      if (imageUrl != null || articleUrl != null) {
        body['specificContent']['com.linkedin.ugc.ShareContent']['shareMediaCategory'] = 'ARTICLE';
        body['specificContent']['com.linkedin.ugc.ShareContent']['media'] = [
          {
            'status': 'READY',
            'description': {
              'text': articleDescription ?? '',
            },
            'originalUrl': articleUrl ?? imageUrl,
            'title': {
              'text': articleTitle ?? 'Shared Content',
            },
          }
        ];
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ugcPosts'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ LinkedIn post error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error posting to LinkedIn profile: $e');
      return null;
    }
  }

  // Post to LinkedIn company page
  static Future<Map<String, dynamic>?> postToCompanyPage({
    required String organizationId,
    required String text,
    String? imageUrl,
    String? articleUrl,
    String? articleTitle,
    String? articleDescription,
    List<String>? hashtags,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      final accessToken = tokens['access_token'];

      // Prepare text with hashtags
      String finalText = text;
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        finalText = '$finalText\n\n$hashtagString';
      }

      final body = <String, dynamic>{
        'author': 'urn:li:organization:$organizationId',
        'lifecycleState': 'PUBLISHED',
        'specificContent': {
          'com.linkedin.ugc.ShareContent': {
            'shareCommentary': {
              'text': finalText,
            },
            'shareMediaCategory': 'NONE',
          },
        },
        'visibility': {
          'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC',
        },
      };

      // Add media if provided
      if (imageUrl != null || articleUrl != null) {
        body['specificContent']['com.linkedin.ugc.ShareContent']['shareMediaCategory'] = 'ARTICLE';
        body['specificContent']['com.linkedin.ugc.ShareContent']['media'] = [
          {
            'status': 'READY',
            'description': {
              'text': articleDescription ?? '',
            },
            'originalUrl': articleUrl ?? imageUrl,
            'title': {
              'text': articleTitle ?? 'Shared Content',
            },
          }
        ];
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ugcPosts'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ LinkedIn company post error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error posting to LinkedIn company page: $e');
      return null;
    }
  }

  // Upload image to LinkedIn
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      // Get user ID
      final profile = await getUserProfile();
      if (profile == null) {
        throw Exception('Could not get user profile');
      }

      final personId = profile['id'];
      final accessToken = tokens['access_token'];

      // Step 1: Register upload
      final registerBody = {
        'registerUploadRequest': {
          'recipes': ['urn:li:digitalmediaRecipe:feedshare-image'],
          'owner': 'urn:li:person:$personId',
          'serviceRelationships': [
            {
              'relationshipType': 'OWNER',
              'identifier': 'urn:li:userGeneratedContent',
            }
          ],
        }
      };

      final registerResponse = await http.post(
        Uri.parse('$_baseUrl/assets?action=registerUpload'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(registerBody),
      );

      if (registerResponse.statusCode != 200) {
        debugPrint('❌ LinkedIn image register error: ${registerResponse.body}');
        return null;
      }

      final registerData = json.decode(registerResponse.body);
      final uploadUrl = registerData['value']['uploadMechanism']
          ['com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest']['uploadUrl'];
      final asset = registerData['value']['asset'];

      // Step 2: Upload binary
      final imageBytes = await imageFile.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
        body: imageBytes,
      );

      if (uploadResponse.statusCode == 201) {
        return asset;
      } else {
        debugPrint('❌ LinkedIn image upload error: ${uploadResponse.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading image to LinkedIn: $e');
      return null;
    }
  }

  // Post with uploaded image
  static Future<Map<String, dynamic>?> postWithImage({
    required String text,
    required File imageFile,
    String? organizationId,
    List<String>? hashtags,
  }) async {
    try {
      debugPrint('📤 Uploading image to LinkedIn...');
      final assetId = await uploadImage(imageFile);
      
      if (assetId == null) {
        throw Exception('Failed to upload image');
      }

      debugPrint('📝 Posting to LinkedIn with image...');
      
      // Prepare text with hashtags
      String finalText = text;
      if (hashtags != null && hashtags.isNotEmpty) {
        final hashtagString = hashtags.map((tag) => '#$tag').join(' ');
        finalText = '$finalText\n\n$hashtagString';
      }

      final tokens = await OAuthService.getStoredTokens('linkedin');
      final accessToken = tokens!['access_token'];

      String author;
      if (organizationId != null) {
        author = 'urn:li:organization:$organizationId';
      } else {
        final profile = await getUserProfile();
        author = 'urn:li:person:${profile!['id']}';
      }

      final body = {
        'author': author,
        'lifecycleState': 'PUBLISHED',
        'specificContent': {
          'com.linkedin.ugc.ShareContent': {
            'shareCommentary': {
              'text': finalText,
            },
            'shareMediaCategory': 'IMAGE',
            'media': [
              {
                'status': 'READY',
                'description': {
                  'text': 'Image post',
                },
                'media': assetId,
                'title': {
                  'text': 'Shared Image',
                },
              }
            ],
          },
        },
        'visibility': {
          'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC',
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/ugcPosts'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        debugPrint('✅ LinkedIn post published successfully');
        return json.decode(response.body);
      } else {
        debugPrint('❌ LinkedIn post with image error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error posting to LinkedIn with image: $e');
      return null;
    }
  }

  // Get user's posts
  static Future<List<Map<String, dynamic>>> getUserPosts({
    int count = 10,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      final profile = await getUserProfile();
      if (profile == null) {
        throw Exception('Could not get user profile');
      }

      final personId = profile['id'];
      final accessToken = tokens['access_token'];

      final response = await http.get(
        Uri.parse('$_baseUrl/ugcPosts?q=authors&authors=List(urn:li:person:$personId)&count=$count&projection=(elements*(id,author,created,lastModified,specificContent,ugcPostHeader,visibility))'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['elements'] ?? []);
      } else {
        debugPrint('❌ LinkedIn user posts error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting LinkedIn user posts: $e');
      return [];
    }
  }

  // Get company page posts
  static Future<List<Map<String, dynamic>>> getCompanyPosts({
    required String organizationId,
    int count = 10,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      final accessToken = tokens['access_token'];

      final response = await http.get(
        Uri.parse('$_baseUrl/ugcPosts?q=authors&authors=List(urn:li:organization:$organizationId)&count=$count&projection=(elements*(id,author,created,lastModified,specificContent,ugcPostHeader,visibility))'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['elements'] ?? []);
      } else {
        debugPrint('❌ LinkedIn company posts error: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting LinkedIn company posts: $e');
      return [];
    }
  }

  // Delete a post
  static Future<bool> deletePost(String postId) async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      final accessToken = tokens['access_token'];
      final response = await http.delete(
        Uri.parse('$_baseUrl/ugcPosts/$postId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      debugPrint('❌ Error deleting LinkedIn post: $e');
      return false;
    }
  }

  // Validate access token
  static Future<bool> validateAccessToken() async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        return false;
      }

      final accessToken = tokens['access_token'];
      return await OAuthService.validateToken('linkedin', accessToken);
    } catch (e) {
      debugPrint('❌ Error validating LinkedIn access token: $e');
      return false;
    }
  }

  // Get company page analytics
  static Future<Map<String, dynamic>?> getCompanyAnalytics({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final tokens = await OAuthService.getStoredTokens('linkedin');
      if (tokens == null) {
        throw Exception('No LinkedIn access token found');
      }

      final accessToken = tokens['access_token'];
      final startTimestamp = (startDate.millisecondsSinceEpoch / 1000).round();
      final endTimestamp = (endDate.millisecondsSinceEpoch / 1000).round();

      final response = await http.get(
        Uri.parse('$_baseUrl/organizationalEntityShareStatistics?q=organizationalEntity&organizationalEntity=urn:li:organization:$organizationId&timeIntervals.timeGranularityType=DAY&timeIntervals.timeRange.start=$startTimestamp&timeIntervals.timeRange.end=$endTimestamp'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ LinkedIn analytics error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting LinkedIn company analytics: $e');
      return null;
    }
  }
} 
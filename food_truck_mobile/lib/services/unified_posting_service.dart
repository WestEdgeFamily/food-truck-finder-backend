import 'dart:io';
import 'package:flutter/foundation.dart';
import 'oauth_service.dart';
import 'instagram_api_client.dart';
import 'facebook_api_client.dart';
import 'twitter_api_client.dart';
import 'linkedin_api_client.dart';
import 'tiktok_api_client.dart';

enum PostType {
  text,
  image,
  video,
  link,
}

enum Platform {
  instagram,
  facebook,
  twitter,
  linkedin,
  tiktok,
}

class UnifiedPost {
  final String content;
  final PostType type;
  final File? mediaFile;
  final String? mediaUrl;
  final String? linkUrl;
  final String? linkTitle;
  final String? linkDescription;
  final List<String> hashtags;
  final List<Platform> targetPlatforms;
  final DateTime? scheduledTime;
  final Map<Platform, String> platformSpecificContent;
  final String? location;

  UnifiedPost({
    required this.content,
    required this.type,
    this.mediaFile,
    this.mediaUrl,
    this.linkUrl,
    this.linkTitle,
    this.linkDescription,
    this.hashtags = const [],
    this.targetPlatforms = const [],
    this.scheduledTime,
    this.platformSpecificContent = const {},
    this.location,
  });
}

class PostResult {
  final Platform platform;
  final bool success;
  final String? postId;
  final String? error;
  final Map<String, dynamic>? data;

  PostResult({
    required this.platform,
    required this.success,
    this.postId,
    this.error,
    this.data,
  });
}

class UnifiedPostingService {
  // Post to multiple platforms simultaneously
  static Future<List<PostResult>> postToMultiplePlatforms(UnifiedPost post) async {
    final results = <PostResult>[];
    final futures = <Future<PostResult>>[];

    // Create futures for each platform
    for (final platform in post.targetPlatforms) {
      final isConnected = await OAuthService.isPlatformConnected(platform.name);
      if (!isConnected) {
        results.add(PostResult(
          platform: platform,
          success: false,
          error: 'Platform not connected',
        ));
        continue;
      }

      switch (platform) {
        case Platform.instagram:
          futures.add(_postToInstagram(post));
          break;
        case Platform.facebook:
          futures.add(_postToFacebook(post));
          break;
        case Platform.twitter:
          futures.add(_postToTwitter(post));
          break;
        case Platform.linkedin:
          futures.add(_postToLinkedIn(post));
          break;
        case Platform.tiktok:
          futures.add(_postToTikTok(post));
          break;
      }
    }

    // Wait for all posts to complete
    if (futures.isNotEmpty) {
      try {
        final platformResults = await Future.wait(futures);
        results.addAll(platformResults);
      } catch (e) {
        debugPrint('❌ Error in unified posting: $e');
      }
    }

    return results;
  }

  // Instagram posting
  static Future<PostResult> _postToInstagram(UnifiedPost post) async {
    try {
      final content = _getPlatformContent(post, Platform.instagram);
      Map<String, dynamic>? result;

      switch (post.type) {
        case PostType.image:
          if (post.mediaFile != null) {
            // Upload image to your server first, then use the URL
            throw UnimplementedError('Image upload to server not implemented');
          } else if (post.mediaUrl != null) {
            result = await InstagramApiClient.postImage(
              imageUrl: post.mediaUrl!,
              caption: content,
              hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.instagram),
            );
          }
          break;
        case PostType.text:
          // Instagram requires images, so we can't post text-only
          return PostResult(
            platform: Platform.instagram,
            success: false,
            error: 'Instagram requires media content',
          );
        default:
          return PostResult(
            platform: Platform.instagram,
            success: false,
            error: 'Unsupported post type for Instagram',
          );
      }

      if (result != null) {
        return PostResult(
          platform: Platform.instagram,
          success: true,
          postId: result['id'],
          data: result,
        );
      } else {
        return PostResult(
          platform: Platform.instagram,
          success: false,
          error: 'Failed to post to Instagram',
        );
      }
    } catch (e) {
      return PostResult(
        platform: Platform.instagram,
        success: false,
        error: e.toString(),
      );
    }
  }

  // Facebook posting
  static Future<PostResult> _postToFacebook(UnifiedPost post) async {
    try {
      final content = _getPlatformContent(post, Platform.facebook);
      final pages = await FacebookApiClient.getUserPages();
      
      if (pages.isEmpty) {
        return PostResult(
          platform: Platform.facebook,
          success: false,
          error: 'No Facebook pages found',
        );
      }

      // Use the first page (you might want to let users choose)
      final page = pages.first;
      final pageId = page['id'];
      final pageAccessToken = page['access_token'];

      Map<String, dynamic>? result;

      switch (post.type) {
        case PostType.text:
          result = await FacebookApiClient.postTextToPage(
            pageId: pageId,
            pageAccessToken: pageAccessToken,
            message: content,
            hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.facebook),
            link: post.linkUrl,
          );
          break;
        case PostType.image:
          result = await FacebookApiClient.postToPage(
            pageId: pageId,
            pageAccessToken: pageAccessToken,
            message: content,
            imageUrl: post.mediaUrl,
            hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.facebook),
          );
          break;
        case PostType.link:
          result = await FacebookApiClient.postTextToPage(
            pageId: pageId,
            pageAccessToken: pageAccessToken,
            message: content,
            hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.facebook),
            link: post.linkUrl,
          );
          break;
        default:
          return PostResult(
            platform: Platform.facebook,
            success: false,
            error: 'Unsupported post type for Facebook',
          );
      }

      if (result != null) {
        return PostResult(
          platform: Platform.facebook,
          success: true,
          postId: result['id'],
          data: result,
        );
      } else {
        return PostResult(
          platform: Platform.facebook,
          success: false,
          error: 'Failed to post to Facebook',
        );
      }
    } catch (e) {
      return PostResult(
        platform: Platform.facebook,
        success: false,
        error: e.toString(),
      );
    }
  }

  // Twitter posting
  static Future<PostResult> _postToTwitter(UnifiedPost post) async {
    try {
      final content = _getPlatformContent(post, Platform.twitter);
      Map<String, dynamic>? result;

      switch (post.type) {
        case PostType.text:
          result = await TwitterApiClient.postTweet(
            text: content,
            hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.twitter),
          );
          break;
        case PostType.image:
          if (post.mediaFile != null) {
            result = await TwitterApiClient.postTweetWithImage(
              text: content,
              imageFile: post.mediaFile!,
              hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.twitter),
            );
          } else {
            // For URL images, we'd need to download and upload
            result = await TwitterApiClient.postTweet(
              text: '$content\n\n${post.mediaUrl ?? ""}',
              hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.twitter),
            );
          }
          break;
        case PostType.link:
          result = await TwitterApiClient.postTweet(
            text: '$content\n\n${post.linkUrl ?? ""}',
            hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.twitter),
          );
          break;
        default:
          return PostResult(
            platform: Platform.twitter,
            success: false,
            error: 'Unsupported post type for Twitter',
          );
      }

      if (result != null) {
        return PostResult(
          platform: Platform.twitter,
          success: true,
          postId: result['data']['id'],
          data: result,
        );
      } else {
        return PostResult(
          platform: Platform.twitter,
          success: false,
          error: 'Failed to post to Twitter',
        );
      }
    } catch (e) {
      return PostResult(
        platform: Platform.twitter,
        success: false,
        error: e.toString(),
      );
    }
  }

  // LinkedIn posting
  static Future<PostResult> _postToLinkedIn(UnifiedPost post) async {
    try {
      final content = _getPlatformContent(post, Platform.linkedin);
      Map<String, dynamic>? result;

      switch (post.type) {
        case PostType.text:
          result = await LinkedInApiClient.postToProfile(
            text: content,
            hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.linkedin),
          );
          break;
        case PostType.image:
          if (post.mediaFile != null) {
            result = await LinkedInApiClient.postWithImage(
              text: content,
              imageFile: post.mediaFile!,
              hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.linkedin),
            );
          } else {
            result = await LinkedInApiClient.postToProfile(
              text: content,
              imageUrl: post.mediaUrl,
              hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.linkedin),
            );
          }
          break;
        case PostType.link:
          result = await LinkedInApiClient.postToProfile(
            text: content,
            articleUrl: post.linkUrl,
            articleTitle: post.linkTitle,
            articleDescription: post.linkDescription,
            hashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.linkedin),
          );
          break;
        default:
          return PostResult(
            platform: Platform.linkedin,
            success: false,
            error: 'Unsupported post type for LinkedIn',
          );
      }

      if (result != null) {
        return PostResult(
          platform: Platform.linkedin,
          success: true,
          postId: result['id'],
          data: result,
        );
      } else {
        return PostResult(
          platform: Platform.linkedin,
          success: false,
          error: 'Failed to post to LinkedIn',
        );
      }
    } catch (e) {
      return PostResult(
        platform: Platform.linkedin,
        success: false,
        error: e.toString(),
      );
    }
  }

  // TikTok posting
  static Future<PostResult> _postToTikTok(UnifiedPost post) async {
    try {
      final content = _getPlatformContent(post, Platform.tiktok);
      Map<String, dynamic>? result;

      switch (post.type) {
        case PostType.video:
          if (post.mediaFile != null) {
            result = await TikTokApiClient.uploadFoodTruckVideo(
              videoFile: post.mediaFile!,
              title: content.length > 150 ? content.substring(0, 150) : content,
              description: content,
              foodHashtags: _optimizeHashtagsForPlatform(post.hashtags, Platform.tiktok),
              location: post.location,
            );
          } else {
            return PostResult(
              platform: Platform.tiktok,
              success: false,
              error: 'TikTok requires video file upload',
            );
          }
          break;
        default:
          return PostResult(
            platform: Platform.tiktok,
            success: false,
            error: 'TikTok only supports video posts',
          );
      }

      if (result != null) {
        return PostResult(
          platform: Platform.tiktok,
          success: true,
          postId: result['publish_id'],
          data: result,
        );
      } else {
        return PostResult(
          platform: Platform.tiktok,
          success: false,
          error: 'Failed to post to TikTok',
        );
      }
    } catch (e) {
      return PostResult(
        platform: Platform.tiktok,
        success: false,
        error: e.toString(),
      );
    }
  }

  // Get platform-specific content
  static String _getPlatformContent(UnifiedPost post, Platform platform) {
    // Check if there's platform-specific content
    if (post.platformSpecificContent.containsKey(platform)) {
      return post.platformSpecificContent[platform]!;
    }

    // Use default content with platform optimizations
    String content = post.content;

    switch (platform) {
      case Platform.twitter:
        // Twitter has character limits
        if (content.length > 240) {
          content = '${content.substring(0, 237)}...';
        }
        break;
      case Platform.linkedin:
        // LinkedIn prefers professional tone
        if (!content.contains('professional') && !content.contains('business')) {
          // Add professional context if missing
        }
        break;
      case Platform.instagram:
        // Instagram loves emojis and engagement
        if (!content.contains('📍') && post.location != null) {
          content = '$content\n📍 ${post.location}';
        }
        break;
      case Platform.tiktok:
        // TikTok prefers catchy, trendy content
        break;
      case Platform.facebook:
        // Facebook works well with longer content
        break;
    }

    return content;
  }

  // Optimize hashtags for each platform
  static List<String> _optimizeHashtagsForPlatform(List<String> hashtags, Platform platform) {
    switch (platform) {
      case Platform.twitter:
        // Twitter: Keep hashtags short and limit to 2-3 per tweet
        return hashtags.take(3).map((tag) => tag.toLowerCase()).toList();
      case Platform.instagram:
        // Instagram: Can use many hashtags, mix popular and niche
        return hashtags.take(30).map((tag) => tag.toLowerCase()).toList();
      case Platform.linkedin:
        // LinkedIn: Use professional hashtags, limit to 3-5
        final professionalHashtags = hashtags.where((tag) => 
          !tag.contains('fun') && !tag.contains('yolo')).take(5).toList();
        return professionalHashtags.map((tag) => tag.toLowerCase()).toList();
      case Platform.tiktok:
        // TikTok: Trending hashtags work best
        return hashtags.take(5).map((tag) => tag.toLowerCase()).toList();
      case Platform.facebook:
        // Facebook: Limited hashtags work better
        return hashtags.take(5).map((tag) => tag.toLowerCase()).toList();
    }
  }

  // Get connected platforms
  static Future<List<Platform>> getConnectedPlatforms() async {
    final connectedPlatforms = <Platform>[];
    
    for (final platform in Platform.values) {
      final isConnected = await OAuthService.isPlatformConnected(platform.name);
      if (isConnected) {
        connectedPlatforms.add(platform);
      }
    }
    
    return connectedPlatforms;
  }

  // Validate post for platforms
  static Map<Platform, String?> validatePostForPlatforms(UnifiedPost post) {
    final validationErrors = <Platform, String?>{};

    for (final platform in post.targetPlatforms) {
      String? error;

      switch (platform) {
        case Platform.instagram:
          if (post.type == PostType.text) {
            error = 'Instagram requires media (image/video)';
          }
          break;
        case Platform.tiktok:
          if (post.type != PostType.video) {
            error = 'TikTok only supports video content';
          }
          break;
        case Platform.twitter:
          final content = _getPlatformContent(post, platform);
          if (content.length > 280) {
            error = 'Content too long for Twitter (${content.length}/280 characters)';
          }
          break;
        case Platform.linkedin:
          // LinkedIn has generous limits
          break;
        case Platform.facebook:
          // Facebook is flexible
          break;
      }

      validationErrors[platform] = error;
    }

    return validationErrors;
  }

  // Create a food truck optimized post
  static UnifiedPost createFoodTruckPost({
    required String content,
    required PostType type,
    File? mediaFile,
    String? mediaUrl,
    String? location,
    List<String>? customHashtags,
    List<Platform>? targetPlatforms,
  }) {
    // Default food truck hashtags
    final defaultHashtags = [
      'foodtruck',
      'streetfood',
      'foodie',
      'delicious',
      'fresh',
      'local',
      'foodlover',
      'yummy',
    ];

    final allHashtags = <String>{
      ...defaultHashtags,
      if (customHashtags != null) ...customHashtags,
    }.toList();

    return UnifiedPost(
      content: content,
      type: type,
      mediaFile: mediaFile,
      mediaUrl: mediaUrl,
      hashtags: allHashtags,
      targetPlatforms: targetPlatforms ?? Platform.values,
      location: location,
    );
  }

  // Schedule post for later
  static Future<List<PostResult>> schedulePost(UnifiedPost post) async {
    // For now, this would store the post in a local database
    // and use a background service to post at the scheduled time
    throw UnimplementedError('Post scheduling not yet implemented');
  }

  // Get posting analytics across platforms
  static Future<Map<Platform, Map<String, dynamic>>> getPostingAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final analytics = <Platform, Map<String, dynamic>>{};

    try {
      // Get analytics from each connected platform
      final connectedPlatforms = await getConnectedPlatforms();

      for (final platform in connectedPlatforms) {
        Map<String, dynamic>? platformAnalytics;

        switch (platform) {
          case Platform.instagram:
            platformAnalytics = await InstagramApiClient.getAccountInsights(
              since: startDate,
              until: endDate,
            );
            break;
          case Platform.facebook:
            final pages = await FacebookApiClient.getUserPages();
            if (pages.isNotEmpty) {
              final pageId = pages.first['id'];
              final pageAccessToken = pages.first['access_token'];
              platformAnalytics = await FacebookApiClient.getPageInsights(
                pageId: pageId,
                pageAccessToken: pageAccessToken,
                since: startDate,
                until: endDate,
              );
            }
            break;
          case Platform.twitter:
            // Twitter API v2 has limited analytics access
            platformAnalytics = {'message': 'Analytics require Twitter API Pro access'};
            break;
          case Platform.linkedin:
            // LinkedIn analytics require company page access
            platformAnalytics = {'message': 'LinkedIn analytics require company page'};
            break;
          case Platform.tiktok:
            platformAnalytics = await TikTokApiClient.getAccountAnalytics(
              metrics: ['PROFILE_VIEW', 'LIKES', 'COMMENTS', 'SHARES', 'REACH'],
              startDate: startDate,
              endDate: endDate,
            );
            break;
        }

        if (platformAnalytics != null) {
          analytics[platform] = platformAnalytics;
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting posting analytics: $e');
    }

    return analytics;
  }
} 
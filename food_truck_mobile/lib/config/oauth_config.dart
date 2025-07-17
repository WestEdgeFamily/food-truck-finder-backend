/// OAuth Configuration for Social Media Integration
/// 
/// IMPORTANT: Before using social media integration, you need to:
/// 1. Create apps on the respective platforms
/// 2. Configure OAuth settings
/// 3. Update the credentials below
/// 
/// See SOCIAL_MEDIA_SETUP.md for detailed instructions
library;

class OAuthConfig {
  // Instagram OAuth Configuration
  // To get these values:
  // 1. Go to https://developers.facebook.com/
  // 2. Create a new app
  // 3. Add Instagram Basic Display product
  // 4. Get your App ID and App Secret
  static const String instagramClientId = 'YOUR_INSTAGRAM_APP_ID_HERE';
  static const String instagramClientSecret = 'YOUR_INSTAGRAM_APP_SECRET_HERE';
  static const String instagramRedirectUri = 'http://localhost:3000/auth/instagram/callback';
  
  // Facebook OAuth Configuration
  // Use the same app as Instagram (Facebook owns Instagram)
  static const String facebookClientId = 'YOUR_FACEBOOK_APP_ID_HERE';
  static const String facebookClientSecret = 'YOUR_FACEBOOK_APP_SECRET_HERE';
  static const String facebookRedirectUri = 'http://localhost:3000/auth/facebook/callback';
  
  // Twitter OAuth Configuration
  // To get these values:
  // 1. Go to https://developer.twitter.com/
  // 2. Create a new app
  // 3. Get your API Key and API Secret
  static const String twitterApiKey = 'YOUR_TWITTER_API_KEY_HERE';
  static const String twitterApiSecret = 'YOUR_TWITTER_API_SECRET_HERE';
  static const String twitterRedirectUri = 'http://localhost:3000/auth/twitter/callback';
  
  // LinkedIn OAuth Configuration
  // To get these values:
  // 1. Go to https://www.linkedin.com/developers/
  // 2. Create a new app
  // 3. Get your Client ID and Client Secret
  static const String linkedinClientId = 'YOUR_LINKEDIN_CLIENT_ID_HERE';
  static const String linkedinClientSecret = 'YOUR_LINKEDIN_CLIENT_SECRET_HERE';
  static const String linkedinRedirectUri = 'http://localhost:3000/auth/linkedin/callback';
  
  // TikTok OAuth Configuration
  // To get these values:
  // 1. Go to https://developers.tiktok.com/
  // 2. Create a new app
  // 3. Get your Client Key and Client Secret
  static const String tiktokClientKey = 'YOUR_TIKTOK_CLIENT_KEY_HERE';
  static const String tiktokClientSecret = 'YOUR_TIKTOK_CLIENT_SECRET_HERE';
  static const String tiktokRedirectUri = 'http://localhost:3000/auth/tiktok/callback';
  
  // OAuth Scopes for each platform
  static const List<String> instagramScopes = [
    'user_profile',
    'user_media',
  ];
  
  static const List<String> facebookScopes = [
    'pages_manage_posts',
    'pages_read_engagement',
    'instagram_basic',
    'instagram_content_publish',
    'business_management',
  ];
  
  static const List<String> twitterScopes = [
    'tweet.read',
    'tweet.write',
    'users.read',
    'offline.access',
  ];
  
  static const List<String> linkedinScopes = [
    'r_liteprofile',
    'r_emailaddress',
    'w_member_social',
    'r_organization_social',
    'w_organization_social',
  ];
  
  static const List<String> tiktokScopes = [
    'user.info.basic',
    'video.list',
    'video.upload',
    'user.info.profile',
    'user.info.stats',
  ];
  
  // Validation methods
  static bool get isInstagramConfigured => 
      instagramClientId != 'YOUR_INSTAGRAM_APP_ID_HERE' &&
      instagramClientSecret != 'YOUR_INSTAGRAM_APP_SECRET_HERE';
  
  static bool get isFacebookConfigured => 
      facebookClientId != 'YOUR_FACEBOOK_APP_ID_HERE' &&
      facebookClientSecret != 'YOUR_FACEBOOK_APP_SECRET_HERE';
  
  static bool get isTwitterConfigured => 
      twitterApiKey != 'YOUR_TWITTER_API_KEY_HERE' &&
      twitterApiSecret != 'YOUR_TWITTER_API_SECRET_HERE';
  
  static bool get isLinkedinConfigured => 
      linkedinClientId != 'YOUR_LINKEDIN_CLIENT_ID_HERE' &&
      linkedinClientSecret != 'YOUR_LINKEDIN_CLIENT_SECRET_HERE';
  
  static bool get isTiktokConfigured => 
      tiktokClientKey != 'YOUR_TIKTOK_CLIENT_KEY_HERE' &&
      tiktokClientSecret != 'YOUR_TIKTOK_CLIENT_SECRET_HERE';
  
  // Helper method to get configured platform count
  static int get configuredPlatformCount {
    int count = 0;
    if (isInstagramConfigured) count++;
    if (isFacebookConfigured) count++;
    if (isTwitterConfigured) count++;
    if (isLinkedinConfigured) count++;
    if (isTiktokConfigured) count++;
    return count;
  }
  
  // Helper method to get all configured platforms
  static List<String> get configuredPlatforms {
    final platforms = <String>[];
    if (isInstagramConfigured) platforms.add('Instagram');
    if (isFacebookConfigured) platforms.add('Facebook');
    if (isTwitterConfigured) platforms.add('Twitter');
    if (isLinkedinConfigured) platforms.add('LinkedIn');
    if (isTiktokConfigured) platforms.add('TikTok');
    return platforms;
  }
} 
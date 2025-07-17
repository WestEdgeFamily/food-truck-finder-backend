# Complete Social Media Integration Setup Guide

This guide will help you set up real OAuth integration for **all major social media platforms**: Instagram, Facebook, Twitter, LinkedIn, and TikTok for your Food Truck App.

## 🚀 What's Included

- **✅ Instagram** - Photo/Video posting and analytics
- **✅ Facebook** - Page posting and business insights  
- **✅ Twitter** - Tweet posting with media
- **✅ LinkedIn** - Professional content sharing
- **✅ TikTok** - Short video content for business
- **✅ Unified Posting** - Post to all platforms simultaneously
- **✅ Real OAuth 2.0** - Secure authentication flows
- **✅ Analytics** - Cross-platform engagement metrics

## Prerequisites

- Developer accounts for each platform
- A website domain for OAuth callbacks (or use the provided test domain)
- Your app compiled and ready for testing

## Step 1: Instagram & Facebook Setup

### 1.1 Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click "Create App"
3. Choose "Business" as app type
4. Fill in your app details:
   - App Name: "Food Truck Finder"
   - App Contact Email: your email
   - Business Account: optional

### 1.2 Add Instagram Basic Display

1. In your Facebook App dashboard, go to "Add Products"
2. Find "Instagram Basic Display" and click "Set Up"
3. Go to Instagram Basic Display → Settings
4. Add OAuth Redirect URIs:
   - `https://foodtruckfinder.app/auth/instagram/callback`
   - `https://localhost:3000/auth/instagram/callback` (for testing)

### 1.3 Add Facebook Login

1. In your Facebook App dashboard, go to "Add Products"
2. Find "Facebook Login" and click "Set Up"
3. Choose "Web" platform
4. Add OAuth Redirect URIs:
   - `https://foodtruckfinder.app/auth/facebook/callback`
   - `https://localhost:3000/auth/facebook/callback` (for testing)

### 1.4 Get Your Credentials

1. Go to Settings → Basic
2. Copy your **App ID** and **App Secret**
3. Note: Keep your App Secret secure and never commit it to version control

## Step 2: Twitter Setup

### 2.1 Create Twitter App

1. Go to [Twitter Developer Portal](https://developer.twitter.com/)
2. Apply for a developer account if you don't have one
3. Create a new app in your developer dashboard
4. Fill in your app details:
   - App Name: "Food Truck Finder"
   - Description: "Social media management for food trucks"
   - Website URL: your website or GitHub repo

### 2.2 Configure OAuth 2.0

1. In your Twitter app dashboard, go to "Settings"
2. Set up OAuth 2.0:
   - Type of App: "Web App"
   - Callback URI: `https://foodtruckfinder.app/auth/twitter/callback`
   - Website URL: your website

### 2.3 Get Your Credentials

1. Go to "Keys and tokens"
2. Copy your **API Key** and **API Secret**
3. Generate **Bearer Token** for API v2 access

## Step 3: LinkedIn Setup

### 3.1 Create LinkedIn App

1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/)
2. Click "Create app"
3. Fill in your app details:
   - App Name: "Food Truck Finder"
   - LinkedIn Page: your business page (required)
   - App logo: upload your app logo

### 3.2 Configure Products

1. In your LinkedIn app dashboard, go to "Products"
2. Request access to:
   - "Share on LinkedIn" (for posting)
   - "Marketing Developer Platform" (for analytics)

### 3.3 Configure OAuth

1. Go to "Auth" tab
2. Add redirect URLs:
   - `https://foodtruckfinder.app/auth/linkedin/callback`
   - `https://localhost:3000/auth/linkedin/callback`

### 3.4 Get Your Credentials

1. In the "Auth" tab, copy your **Client ID** and **Client Secret**

## Step 4: TikTok Setup

### 4.1 Create TikTok for Business App

1. Go to [TikTok for Developers](https://developers.tiktok.com/)
2. Click "Get Started" and create an account
3. Create a new app:
   - App Name: "Food Truck Finder"
   - App Type: "Official Business Partner"
   - Use Case: "Social Media Management"

### 4.2 Configure Login Kit

1. In your TikTok app dashboard, go to "Login Kit"
2. Add redirect URIs:
   - `https://foodtruckfinder.app/auth/tiktok/callback`
   - `https://localhost:3000/auth/tiktok/callback`

### 4.3 Get Your Credentials

1. Go to "Basic Info"
2. Copy your **Client Key** and **Client Secret**

## Step 5: Configure Your Flutter App

### 5.1 Update OAuth Configuration

1. Open `lib/config/oauth_config.dart`
2. Replace all placeholder values:

```dart
class OAuthConfig {
  // Instagram OAuth Configuration
  static const String instagramClientId = 'YOUR_FACEBOOK_APP_ID';
  static const String instagramClientSecret = 'YOUR_FACEBOOK_APP_SECRET';
  
  // Facebook OAuth Configuration  
  static const String facebookClientId = 'YOUR_FACEBOOK_APP_ID';
  static const String facebookClientSecret = 'YOUR_FACEBOOK_APP_SECRET';
  
  // Twitter OAuth Configuration
  static const String twitterApiKey = 'YOUR_TWITTER_API_KEY';
  static const String twitterApiSecret = 'YOUR_TWITTER_API_SECRET';
  
  // LinkedIn OAuth Configuration
  static const String linkedinClientId = 'YOUR_LINKEDIN_CLIENT_ID';
  static const String linkedinClientSecret = 'YOUR_LINKEDIN_CLIENT_SECRET';
  
  // TikTok OAuth Configuration
  static const String tiktokClientKey = 'YOUR_TIKTOK_CLIENT_KEY';
  static const String tiktokClientSecret = 'YOUR_TIKTOK_CLIENT_SECRET';
}
```

### 5.2 Update Redirect URIs (Optional)

If you have your own domain, update the redirect URIs in the config file.

## Step 6: Set Up Callback Handling

### 6.1 Backend Server (Required)

Create an Express.js server to handle OAuth callbacks:

```javascript
const express = require('express');
const app = express();

// Instagram callback
app.get('/auth/instagram/callback', (req, res) => {
  const { code, state, error } = req.query;
  if (error) {
    return res.redirect(`foodtruckapp://oauth/instagram?error=${error}`);
  }
  res.redirect(`foodtruckapp://oauth/instagram?code=${code}&state=${state}`);
});

// Facebook callback
app.get('/auth/facebook/callback', (req, res) => {
  const { code, state, error } = req.query;
  if (error) {
    return res.redirect(`foodtruckapp://oauth/facebook?error=${error}`);
  }
  res.redirect(`foodtruckapp://oauth/facebook?code=${code}&state=${state}`);
});

// Twitter callback
app.get('/auth/twitter/callback', (req, res) => {
  const { code, state, error } = req.query;
  if (error) {
    return res.redirect(`foodtruckapp://oauth/twitter?error=${error}`);
  }
  res.redirect(`foodtruckapp://oauth/twitter?code=${code}&state=${state}`);
});

// LinkedIn callback
app.get('/auth/linkedin/callback', (req, res) => {
  const { code, state, error } = req.query;
  if (error) {
    return res.redirect(`foodtruckapp://oauth/linkedin?error=${error}`);
  }
  res.redirect(`foodtruckapp://oauth/linkedin?code=${code}&state=${state}`);
});

// TikTok callback
app.get('/auth/tiktok/callback', (req, res) => {
  const { code, state, error } = req.query;
  if (error) {
    return res.redirect(`foodtruckapp://oauth/tiktok?error=${error}`);
  }
  res.redirect(`foodtruckapp://oauth/tiktok?code=${code}&state=${state}`);
});

app.listen(3000, () => {
  console.log('OAuth callback server running on port 3000');
});
```

### 6.2 Deploy Your Callback Server

Deploy your callback server to:
- Heroku
- Vercel
- Netlify Functions
- AWS Lambda
- Your own VPS

## Step 7: Using the Unified Posting Service

### 7.1 Basic Usage

```dart
import 'package:your_app/services/unified_posting_service.dart';

// Create a food truck post
final post = UnifiedPostingService.createFoodTruckPost(
  content: "🌮 Fresh tacos available now at Main Street! Come grab lunch!",
  type: PostType.image,
  mediaUrl: "https://your-server.com/taco-image.jpg",
  location: "Main Street, Downtown",
  customHashtags: ["tacos", "lunch", "downtown"],
  targetPlatforms: [Platform.instagram, Platform.facebook, Platform.twitter],
);

// Post to multiple platforms
final results = await UnifiedPostingService.postToMultiplePlatforms(post);

// Check results
for (final result in results) {
  if (result.success) {
    print("✅ Posted to ${result.platform.name}: ${result.postId}");
  } else {
    print("❌ Failed to post to ${result.platform.name}: ${result.error}");
  }
}
```

### 7.2 Platform-Specific Content

```dart
final post = UnifiedPost(
  content: "Default content for all platforms",
  type: PostType.text,
  hashtags: ["foodtruck", "fresh", "local"],
  targetPlatforms: [Platform.twitter, Platform.linkedin, Platform.facebook],
  platformSpecificContent: {
    Platform.twitter: "🌮 Fresh tacos now! #foodtruck #tacos",
    Platform.linkedin: "Our food truck business is thriving with fresh, locally-sourced ingredients. Visit us for the best tacos in town! #foodservice #business #local",
    Platform.facebook: "🌮 Hey everyone! We're serving up fresh tacos with locally-sourced ingredients. Come visit us for lunch! Tag your friends who love great food! 😋",
  },
);
```

### 7.3 Validation Before Posting

```dart
// Validate post for all target platforms
final errors = UnifiedPostingService.validatePostForPlatforms(post);

bool canPost = true;
for (final platform in post.targetPlatforms) {
  if (errors[platform] != null) {
    print("❌ ${platform.name}: ${errors[platform]}");
    canPost = false;
  }
}

if (canPost) {
  final results = await UnifiedPostingService.postToMultiplePlatforms(post);
}
```

### 7.4 Get Analytics

```dart
// Get analytics across all platforms
final analytics = await UnifiedPostingService.getPostingAnalytics(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

for (final platform in analytics.keys) {
  final data = analytics[platform]!;
  print("📊 ${platform.name} analytics: $data");
}
```

## Step 8: Testing

### 8.1 Test Each Platform

1. Open your app
2. Go to Settings → Connect Accounts
3. Connect each platform one by one
4. Verify the OAuth flow works for each
5. Test posting with the unified service

### 8.2 Debug Common Issues

- **OAuth errors**: Check redirect URIs match exactly
- **Token errors**: Verify app credentials are correct
- **Permission errors**: Ensure apps have required permissions
- **Posting errors**: Check content meets platform requirements

## Step 9: Production Deployment

### 9.1 App Review Process

Most platforms require app review for production:

1. **Facebook/Instagram**: Submit for app review
2. **Twitter**: Apply for Elevated access
3. **LinkedIn**: Request production access
4. **TikTok**: Submit for production approval

### 9.2 Required Documentation

Prepare for app review:
- Privacy policy URL
- Terms of service URL
- App screenshots
- Use case description
- Data handling explanation

## 🎯 Platform-Specific Features

### Instagram
- ✅ Image/Video posting
- ✅ Story posting (coming soon)
- ✅ Analytics and insights
- ✅ Hashtag optimization

### Facebook  
- ✅ Page posting
- ✅ Image/Video/Link sharing
- ✅ Post scheduling
- ✅ Page insights and analytics

### Twitter
- ✅ Text and media tweets
- ✅ Thread posting (coming soon)
- ✅ Real-time engagement
- ✅ Hashtag trending

### LinkedIn
- ✅ Professional content sharing
- ✅ Company page posting
- ✅ Article sharing
- ✅ Business networking

### TikTok
- ✅ Short video posting
- ✅ Trending hashtags
- ✅ Business analytics
- ✅ Food truck optimized content

## 🔧 Advanced Features

### Cross-Platform Analytics
```dart
// Get unified analytics dashboard
final analytics = await UnifiedPostingService.getPostingAnalytics(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);

// Analyze performance across platforms
final totalReach = analytics.values
  .map((data) => data['reach'] ?? 0)
  .fold(0, (a, b) => a + b);
```

### Content Optimization
```dart
// Auto-optimize content for each platform
final post = UnifiedPost(
  content: longFormContent,
  type: PostType.text,
  targetPlatforms: Platform.values, // All platforms
);

// Service automatically optimizes for each platform:
// - Twitter: Truncated to 280 chars
// - LinkedIn: Professional tone
// - Instagram: Emoji-rich with location
// - TikTok: Trending hashtags
// - Facebook: Engagement-focused
```

### Bulk Operations
```dart
// Post multiple pieces of content
final posts = [post1, post2, post3];
final allResults = <PostResult>[];

for (final post in posts) {
  final results = await UnifiedPostingService.postToMultiplePlatforms(post);
  allResults.addAll(results);
}
```

## 🚨 Security Best Practices

1. **Never commit secrets to version control**
2. **Use environment variables for sensitive data**
3. **Implement proper error handling**
4. **Validate all callback parameters**
5. **Use HTTPS for all OAuth redirects**
6. **Regularly refresh access tokens**
7. **Monitor for suspicious activity**

## 📞 Support

For additional help:
- [Facebook Developer Documentation](https://developers.facebook.com/docs/)
- [Instagram Basic Display API](https://developers.facebook.com/docs/instagram-basic-display-api)
- [Twitter API v2 Documentation](https://developer.twitter.com/en/docs/twitter-api)
- [LinkedIn API Documentation](https://docs.microsoft.com/en-us/linkedin/)
- [TikTok for Developers](https://developers.tiktok.com/doc/)
- [OAuth 2.0 Security Best Practices](https://tools.ietf.org/html/draft-ietf-oauth-security-topics)

## 🎉 You're Done!

You now have a complete social media management system that can:

- ✅ **Connect to all major platforms**
- ✅ **Post unified content across platforms**
- ✅ **Optimize content for each platform**
- ✅ **Track analytics and engagement**
- ✅ **Manage multiple accounts securely**

Your food truck app now has **enterprise-level social media capabilities**! 🚀

Remember to test thoroughly before releasing to production and follow each platform's guidelines for business use. 
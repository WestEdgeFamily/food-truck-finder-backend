class SocialAccount {
  final String id;
  final String platform;
  final String? accountName;
  final String platformDisplayName;
  final bool isActive;
  final int followers;
  final String? avatarUrl;
  final String? profileUrl;
  final Map<String, dynamic>? metadata;

  SocialAccount({
    required this.id,
    required this.platform,
    this.accountName,
    required this.platformDisplayName,
    required this.isActive,
    required this.followers,
    this.avatarUrl,
    this.profileUrl,
    this.metadata,
  });

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    return SocialAccount(
      id: json['id'] ?? '',
      platform: json['platform'] ?? '',
      accountName: json['accountName'] ?? json['account_name'],
      platformDisplayName: json['platformDisplayName'] ?? json['platform_display_name'] ?? '',
      isActive: json['isActive'] ?? json['is_active'] ?? false,
      followers: json['followers'] ?? 0,
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      profileUrl: json['profileUrl'] ?? json['profile_url'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'accountName': accountName,
      'platformDisplayName': platformDisplayName,
      'isActive': isActive,
      'followers': followers,
      'avatarUrl': avatarUrl,
      'profileUrl': profileUrl,
      'metadata': metadata,
    };
  }

  SocialAccount copyWith({
    String? id,
    String? platform,
    String? accountName,
    String? platformDisplayName,
    bool? isActive,
    int? followers,
    String? avatarUrl,
    String? profileUrl,
    Map<String, dynamic>? metadata,
  }) {
    return SocialAccount(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      accountName: accountName ?? this.accountName,
      platformDisplayName: platformDisplayName ?? this.platformDisplayName,
      isActive: isActive ?? this.isActive,
      followers: followers ?? this.followers,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileUrl: profileUrl ?? this.profileUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SocialAccount(id: $id, platform: $platform, accountName: $accountName, followers: $followers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialAccount &&
        other.id == id &&
        other.platform == platform;
  }

  @override
  int get hashCode {
    return id.hashCode ^ platform.hashCode;
  }
} 
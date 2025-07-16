class SocialPost {
  final String id;
  final String userId;
  final String truckId;
  final String content;
  final List<String> platforms;
  final List<String> mediaUrls;
  final DateTime scheduledTime;
  final String status;
  final Map<String, dynamic>? analytics;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  bool get isScheduled => status == 'scheduled';
  bool get isPublished => status == 'published';
  DateTime? get publishedTime => isPublished ? updatedAt : null;

  SocialPost({
    required this.id,
    required this.userId,
    required this.truckId,
    required this.content,
    required this.platforms,
    this.mediaUrls = const [],
    required this.scheduledTime,
    required this.status,
    this.analytics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      truckId: json['truckId'] ?? '',
      content: json['content'] ?? '',
      platforms: List<String>.from(json['platforms'] ?? []),
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      scheduledTime: DateTime.parse(json['scheduledTime'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'draft',
      analytics: json['analytics'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'truckId': truckId,
      'content': content,
      'platforms': platforms,
      'mediaUrls': mediaUrls,
      'scheduledTime': scheduledTime.toIso8601String(),
      'status': status,
      'analytics': analytics,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
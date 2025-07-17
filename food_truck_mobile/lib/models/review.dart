class Review {
  final String id;
  final String userId;
  final String userName;
  final String truckId;
  final int rating;
  final String comment;
  final List<String> photos;
  final int helpfulCount;
  final bool hasUserVotedHelpful;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReviewResponse? response;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.truckId,
    required this.rating,
    required this.comment,
    this.photos = const [],
    this.helpfulCount = 0,
    this.hasUserVotedHelpful = false,
    required this.createdAt,
    required this.updatedAt,
    this.response,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Handle userId that might be populated as an object
    String userId = '';
    if (json['userId'] != null) {
      if (json['userId'] is String) {
        userId = json['userId'];
      } else if (json['userId'] is Map) {
        userId = json['userId']['_id'] ?? '';
      }
    }
    
    return Review(
      id: json['_id'] ?? '',
      userId: userId,
      userName: json['userName'] ?? 'Anonymous',
      truckId: json['truckId'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      helpfulCount: json['helpfulCount'] ?? 0,
      hasUserVotedHelpful: json['hasUserVotedHelpful'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      response: json['response'] != null 
        ? ReviewResponse.fromJson(json['response']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'userName': userName,
      'truckId': truckId,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'helpfulCount': helpfulCount,
      'hasUserVotedHelpful': hasUserVotedHelpful,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'response': response?.toJson(),
    };
  }
}

class ReviewResponse {
  final String text;
  final DateTime respondedAt;
  final String respondedBy;

  ReviewResponse({
    required this.text,
    required this.respondedAt,
    required this.respondedBy,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      text: json['text'] ?? '',
      respondedAt: DateTime.parse(json['respondedAt'] ?? DateTime.now().toIso8601String()),
      respondedBy: json['respondedBy'] ?? 'Owner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'respondedAt': respondedAt.toIso8601String(),
      'respondedBy': respondedBy,
    };
  }
}

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    final dist = json['ratingDistribution'] ?? {};
    // Convert string keys to int keys for the rating distribution
    final Map<int, int> ratingDist = {};
    
    // Debug print to help with troubleshooting
    print('📊 ReviewStats.fromJson - ratingDistribution: $dist');
    print('📊 ReviewStats.fromJson - dist type: ${dist.runtimeType}');
    
    try {
      // Handle both string and int keys from backend
      for (int i = 1; i <= 5; i++) {
        // Try both string and int keys
        final stringKey = i.toString();
        final value = dist[stringKey] ?? dist[i] ?? 0;
        
        // Ensure value is converted to int properly
        if (value is int) {
          ratingDist[i] = value;
        } else if (value is double) {
          ratingDist[i] = value.toInt();
        } else if (value is String) {
          ratingDist[i] = int.tryParse(value) ?? 0;
        } else {
          ratingDist[i] = 0;
        }
      }
    } catch (e) {
      print('❌ Error in ReviewStats.fromJson: $e');
      // If any error occurs, create a safe default distribution
      for (int i = 1; i <= 5; i++) {
        ratingDist[i] = 0;
      }
    }
    
    print('📊 Final ratingDistribution: $ratingDist');
    
    return ReviewStats(
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: ratingDist,
    );
  }
} 
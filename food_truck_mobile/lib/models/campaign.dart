class Campaign {
  final String id;
  final String name;
  final String description;
  final String truckId;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> platforms;
  final String status;
  final Map<String, dynamic>? goals;
  final Map<String, dynamic>? analytics;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  String get type => analytics?['type'] ?? 'general';
  double get progress {
    if (startDate.isAfter(DateTime.now())) return 0.0;
    if (endDate.isBefore(DateTime.now())) return 100.0;
    final total = endDate.difference(startDate).inDays;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / total * 100).clamp(0.0, 100.0);
  }
  int get daysRemaining => endDate.difference(DateTime.now()).inDays.clamp(0, 999);

  Campaign({
    required this.id,
    required this.name,
    required this.description,
    required this.truckId,
    required this.startDate,
    required this.endDate,
    required this.platforms,
    required this.status,
    this.goals,
    this.analytics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      truckId: json['truckId'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      platforms: List<String>.from(json['platforms'] ?? []),
      status: json['status'] ?? 'draft',
      goals: json['goals'],
      analytics: json['analytics'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'truckId': truckId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'platforms': platforms,
      'status': status,
      'goals': goals,
      'analytics': analytics,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
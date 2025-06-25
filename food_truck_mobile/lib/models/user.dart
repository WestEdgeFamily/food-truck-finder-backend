class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'customer' or 'owner'
  final String? businessName; // For food truck owners
  final bool isActive;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.businessName,
    this.isActive = true,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // ROBUST ID HANDLING: Try multiple possible ID fields and pick the first non-empty one
    String userId = '';
    
    // Priority order: id, _id, userId
    if (json['id'] != null && json['id'].toString().isNotEmpty) {
      userId = json['id'].toString();
    } else if (json['_id'] != null && json['_id'].toString().isNotEmpty) {
      userId = json['_id'].toString();
    } else if (json['userId'] != null && json['userId'].toString().isNotEmpty) {
      userId = json['userId'].toString();
    }
    
    return User(
      id: userId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      businessName: json['businessName'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'businessName': businessName,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? businessName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isCustomer => role == 'customer';

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 
class FoodTruck {
  final String id;
  final String name;
  final String businessName;
  final String description;
  final String ownerId;
  final List<String> cuisineTypes;
  final String? image;
  final String? email;
  final String? website;
  final double? latitude;
  final double? longitude;
  final String? address;
  final Map<String, dynamic>? schedule;
  final List<MenuItem>? menu;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final DateTime? lastUpdated;
  final DateTime? createdAt;

  FoodTruck({
    required this.id,
    required this.name,
    required this.businessName,
    required this.description,
    required this.ownerId,
    this.cuisineTypes = const [],
    this.image,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
    this.address,
    this.schedule,
    this.menu,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOpen = false,
    this.lastUpdated,
    this.createdAt,
  });

  factory FoodTruck.fromJson(Map<String, dynamic> json) {
    return FoodTruck(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      businessName: json['businessName'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['ownerId'] ?? json['owner'] ?? '',
      cuisineTypes: json['cuisineTypes'] != null
          ? List<String>.from(json['cuisineTypes'])
          : json['cuisine'] != null
              ? [json['cuisine']]
              : [],
      image: json['image'],
      email: json['email'],
      website: json['website'],
      latitude: json['location']?['latitude']?.toDouble() ?? 
                json['latitude']?.toDouble(),
      longitude: json['location']?['longitude']?.toDouble() ?? 
                 json['longitude']?.toDouble(),
      address: json['location']?['address'] ?? json['address'],
      schedule: json['schedule'] as Map<String, dynamic>?,
      menu: json['menu'] != null
          ? (json['menu'] as List).map((item) => MenuItem.fromJson(item)).toList()
          : null,
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      isOpen: json['isOpen'] ?? false,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'businessName': businessName,
      'description': description,
      'ownerId': ownerId,
      'cuisineTypes': cuisineTypes,
      'image': image,
      'email': email,
      'website': website,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
      'schedule': schedule,
      'menu': menu?.map((item) => item.toJson()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
      'isOpen': isOpen,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  FoodTruck copyWith({
    String? id,
    String? name,
    String? businessName,
    String? description,
    String? ownerId,
    List<String>? cuisineTypes,
    String? image,
    String? email,
    String? website,
    double? latitude,
    double? longitude,
    String? address,
    Map<String, dynamic>? schedule,
    List<MenuItem>? menu,
    double? rating,
    int? reviewCount,
    bool? isOpen,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return FoodTruck(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      image: image ?? this.image,
      email: email ?? this.email,
      website: website ?? this.website,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      schedule: schedule ?? this.schedule,
      menu: menu ?? this.menu,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOpen: isOpen ?? this.isOpen,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
  
  String get cuisineTypesString => cuisineTypes.join(', ');

  @override
  String toString() {
    return 'FoodTruck(id: $id, name: $name, businessName: $businessName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodTruck && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? category;
  final String? image;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.category,
    this.image,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      category: json['category'],
      image: json['image'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': image,
      'isAvailable': isAvailable,
    };
  }
} 
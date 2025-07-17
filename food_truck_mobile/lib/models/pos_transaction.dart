import 'package:flutter/foundation.dart';

/// Model representing a POS transaction
class PosTransaction {
  final String id;
  final String posType;
  final DateTime createdAt;
  final double totalAmount;
  final String currency;
  final String? locationId;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final List<PosTransactionItem> items;
  final String? customerId;
  final String? customerName;
  final String paymentMethod;
  final String status;

  PosTransaction({
    required this.id,
    required this.posType,
    required this.createdAt,
    required this.totalAmount,
    this.currency = 'USD',
    this.locationId,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.items,
    this.customerId,
    this.customerName,
    required this.paymentMethod,
    required this.status,
  });

  /// Create from Square order data
  factory PosTransaction.fromSquare(Map<String, dynamic> order) {
    final lineItems = order['line_items'] as List? ?? [];
    final totalMoney = order['total_money'] ?? {};
    final location = order['location'] ?? {};
    
    return PosTransaction(
      id: order['id'],
      posType: 'square',
      createdAt: DateTime.parse(order['created_at']),
      totalAmount: (totalMoney['amount'] ?? 0) / 100.0, // Square uses cents
      currency: totalMoney['currency'] ?? 'USD',
      locationId: order['location_id'],
      locationName: location['name'],
      latitude: location['coordinates']?['latitude'],
      longitude: location['coordinates']?['longitude'],
      items: lineItems.map((item) => PosTransactionItem.fromSquare(item)).toList(),
      customerId: order['customer_id'],
      paymentMethod: order['tenders']?[0]?['type'] ?? 'UNKNOWN',
      status: order['state'] ?? 'COMPLETED',
    );
  }

  /// Create from Toast order data
  factory PosTransaction.fromToast(Map<String, dynamic> order) {
    final selections = order['selections'] as List? ?? [];
    final payment = order['paymentInfo'] ?? {};
    
    return PosTransaction(
      id: order['guid'],
      posType: 'toast',
      createdAt: DateTime.parse(order['createdDate']),
      totalAmount: (order['amount'] ?? 0.0).toDouble(),
      currency: 'USD',
      locationId: order['restaurantGuid'],
      locationName: order['restaurantName'],
      items: selections.map((item) => PosTransactionItem.fromToast(item)).toList(),
      customerId: order['customerId'],
      customerName: order['customerName'],
      paymentMethod: payment['type'] ?? 'UNKNOWN',
      status: order['businessState'] ?? 'PAID',
    );
  }

  /// Create from Clover order data
  factory PosTransaction.fromClover(Map<String, dynamic> order) {
    final lineItems = order['lineItems']?['elements'] as List? ?? [];
    
    return PosTransaction(
      id: order['id'],
      posType: 'clover',
      createdAt: DateTime.fromMillisecondsSinceEpoch(order['createdTime']),
      totalAmount: (order['total'] ?? 0) / 100.0, // Clover uses cents
      currency: order['currency'] ?? 'USD',
      locationId: order['device']?['id'],
      items: lineItems.map((item) => PosTransactionItem.fromClover(item)).toList(),
      customerId: order['customer']?['id'],
      customerName: order['customer']?['name'],
      paymentMethod: order['payType'] ?? 'UNKNOWN',
      status: order['state'] ?? 'paid',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'posType': posType,
    'createdAt': createdAt.toIso8601String(),
    'totalAmount': totalAmount,
    'currency': currency,
    'locationId': locationId,
    'locationName': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'items': items.map((i) => i.toJson()).toList(),
    'customerId': customerId,
    'customerName': customerName,
    'paymentMethod': paymentMethod,
    'status': status,
  };
}

/// Model representing an item in a POS transaction
class PosTransactionItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final double totalPrice;
  final String? category;
  final List<String> modifiers;

  PosTransactionItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.category,
    this.modifiers = const [],
  });

  /// Create from Square line item
  factory PosTransactionItem.fromSquare(Map<String, dynamic> item) {
    final basePriceMoney = item['base_price_money'] ?? {};
    final totalPriceMoney = item['total_price_money'] ?? {};
    final modifiers = item['modifiers'] as List? ?? [];
    
    return PosTransactionItem(
      id: item['uid'] ?? '',
      name: item['name'] ?? 'Unknown Item',
      quantity: int.parse(item['quantity'] ?? '1'),
      price: (basePriceMoney['amount'] ?? 0) / 100.0,
      totalPrice: (totalPriceMoney['amount'] ?? 0) / 100.0,
      category: item['catalog_object_id'],
      modifiers: modifiers.map((m) => m['name'].toString()).toList(),
    );
  }

  /// Create from Toast selection
  factory PosTransactionItem.fromToast(Map<String, dynamic> selection) {
    final modifiers = selection['modifiers'] as List? ?? [];
    
    return PosTransactionItem(
      id: selection['guid'] ?? '',
      name: selection['displayName'] ?? 'Unknown Item',
      quantity: selection['quantity'] ?? 1,
      price: (selection['price'] ?? 0.0).toDouble(),
      totalPrice: (selection['totalPrice'] ?? 0.0).toDouble(),
      category: selection['salesCategory'],
      modifiers: modifiers.map((m) => m['displayName'].toString()).toList(),
    );
  }

  /// Create from Clover line item
  factory PosTransactionItem.fromClover(Map<String, dynamic> item) {
    final modifications = item['modifications'] as List? ?? [];
    
    return PosTransactionItem(
      id: item['id'] ?? '',
      name: item['name'] ?? 'Unknown Item',
      quantity: item['unitQty'] ?? 1,
      price: (item['price'] ?? 0) / 100.0,
      totalPrice: ((item['price'] ?? 0) * (item['unitQty'] ?? 1)) / 100.0,
      category: item['item']?['category']?['name'],
      modifiers: modifications.map((m) => m['name'].toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'price': price,
    'totalPrice': totalPrice,
    'category': category,
    'modifiers': modifiers,
  };
}
import 'dart:convert';

import 'cart_item.dart';

enum OrderStatus { pending, shipping, delivered, cancelled }

class Order {
  final String id;
  final List<CartItem> items;
  final double subTotal;
  final double shippingFee;
  final double discount;
  final double total;
  final String paymentMethod; // 'Momo' or 'COD'
  final String address;
  final OrderStatus status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.subTotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.address,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((e) => e.toJson()).toList(),
    'subTotal': subTotal,
    'shippingFee': shippingFee,
    'discount': discount,
    'total': total,
    'paymentMethod': paymentMethod,
    'address': address,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      subTotal: (json['subTotal'] as num).toDouble(),
      shippingFee: (json['shippingFee'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      address: json['address'] as String,
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static List<Order> listFromJsonString(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static String listToJsonString(List<Order> orders) {
    return jsonEncode(orders.map((o) => o.toJson()).toList());
  }
}

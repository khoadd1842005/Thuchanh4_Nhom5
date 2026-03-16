import 'cart_item.dart';

enum OrderStatus { pending, delivering, delivered, cancelled }

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final String address;
  final String paymentMethod;
  final DateTime orderDate;
  final OrderStatus status;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.paymentMethod,
    required this.orderDate,
    this.status = OrderStatus.pending,
  });

  Order copyWith({
    OrderStatus? status,
  }) {
    return Order(
      id: id,
      items: items,
      totalAmount: totalAmount,
      address: address,
      paymentMethod: paymentMethod,
      orderDate: orderDate,
      status: status ?? this.status,
    );
  }

  // To/From JSON if persistence is needed later
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'address': address,
      'paymentMethod': paymentMethod,
      'orderDate': orderDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      address: json['address'],
      paymentMethod: json['paymentMethod'],
      orderDate: DateTime.parse(json['orderDate']),
      status: OrderStatus.values.byName(json['status']),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((o) => o.status == status).toList();
  }

  void placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  }) {
    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: items,
      totalAmount: totalAmount,
      address: address,
      paymentMethod: paymentMethod,
      orderDate: DateTime.now(),
      status: OrderStatus.pending,
    );
    _orders.insert(0, newOrder);
    notifyListeners();
  }
}

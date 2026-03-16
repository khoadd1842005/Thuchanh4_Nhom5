import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import '../models/cart_item.dart';

class OrderProvider extends ChangeNotifier {
  static const String _orderStorageKey = 'shopping_orders';

  final List<Order> _orders = [];
  bool _isLoading = true;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_orderStorageKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _orders
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((e) => Order.fromJson(Map<String, dynamic>.from(e))),
            );
        }
      }
    } catch (_) {
      _orders.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((o) => o.status == status).toList();
  }

  Future<void> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  }) async {
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
    await _persistOrders();
    notifyListeners();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(status: status);
    await _persistOrders();
    notifyListeners();
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId: orderId, status: OrderStatus.cancelled);
  }

  Future<void> _persistOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_orders.map((order) => order.toJson()).toList());
    await prefs.setString(_orderStorageKey, encoded);
  }
}

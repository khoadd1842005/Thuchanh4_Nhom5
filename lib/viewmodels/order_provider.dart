import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  static const String _ordersKey = 'orders_storage';

  List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  Future<void> loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_ordersKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _orders = decoded
              .whereType<Map>()
              .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: true);
        }
      }
    } catch (_) {
      _orders = [];
    }
    notifyListeners();
  }

  Future<void> addOrder(Order order) async {
    _orders.insert(0, order);
    await _persistOrders();
    notifyListeners();
  }

  Future<void> _persistOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await prefs.setString(_ordersKey, encoded);
  }

  List<Order> ordersByStatus(OrderStatus status) =>
      _orders.where((o) => o.status == status).toList(growable: false);
}

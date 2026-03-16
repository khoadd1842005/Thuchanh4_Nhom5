import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartViewModel extends ChangeNotifier {
  static const String _cartStorageKey = 'shopping_cart_items';
  List<CartItem> _items = [];
  bool _isLoading = true;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items = decoded.whereType<Map<String, dynamic>>().map(CartItem.fromJson).toList(growable: true);
        }
      }
    } catch (_) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart({
    required Product product,
    required String size,
    required String color,
    int quantity = 1,
  }) async {
    final existingIndex = _items.indexWhere(
      (item) => item.isSameVariant(productId: product.id, size: size, color: color),
    );

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _items.add(CartItem(
        product: product, 
        selectedSize: size, 
        selectedColor: color, 
        quantity: quantity,
      ));
    }
    await _persistCart();
    notifyListeners();
  }

  Future<void> increaseQuantity(CartItem targetItem) async {
    final index = _items.indexOf(targetItem);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
      await _persistCart();
      notifyListeners();
    }
  }

  Future<void> decreaseQuantity(CartItem targetItem) async {
    final index = _items.indexOf(targetItem);
    if (index >= 0) {
      if (_items[index].quantity <= 1) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: _items[index].quantity - 1);
      }
      await _persistCart();
      notifyListeners();
    }
  }

  Future<void> removeItem(CartItem targetItem) async {
    _items.remove(targetItem);
    await _persistCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items = [];
    await _persistCart();
    notifyListeners();
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_cartStorageKey, encoded);
  }
}

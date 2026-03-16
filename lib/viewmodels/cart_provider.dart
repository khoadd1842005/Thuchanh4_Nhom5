import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  static const String _cartStorageKey = 'shopping_cart_items';

  List<CartItem> _items = [];
  bool _isLoading = true;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  List<CartItem> get selectedItems =>
      _items.where((item) => item.isSelected).toList(growable: false);

  bool get isAllSelected =>
      _items.isNotEmpty && selectedItems.length == _items.length;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalProductTypes => _items.length;
  int get selectedItemsCount => selectedItems.length;

  double get totalPrice => selectedItems.fold(
        0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartStorageKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items = decoded
              .whereType<Map>()
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: true);
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
      _items.add(
        CartItem(
          product: product,
          selectedSize: size,
          selectedColor: color,
          quantity: quantity,
          isSelected: true,
        ),
      );
    }

    await _persistCart();
    notifyListeners();
  }

  Future<void> toggleSelectAll(bool isSelected) async {
    _items = _items
        .map((item) => item.copyWith(isSelected: isSelected))
        .toList(growable: true);
    await _persistCart();
    notifyListeners();
  }

  Future<void> toggleItemSelection(CartItem targetItem, bool isSelected) async {
    final index = _findItemIndex(targetItem);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(isSelected: isSelected);
    await _persistCart();
    notifyListeners();
  }

  bool shouldConfirmRemoveWhenDecrease(CartItem targetItem) {
    final index = _findItemIndex(targetItem);
    if (index == -1) return false;
    return _items[index].quantity <= 1;
  }

  Future<void> increaseQuantity(CartItem targetItem) async {
    final index = _findItemIndex(targetItem);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
    await _persistCart();
    notifyListeners();
  }

  Future<void> decreaseQuantity(CartItem targetItem) async {
    final index = _findItemIndex(targetItem);
    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity - 1);
      await _persistCart();
      notifyListeners();
    }
  }

  Future<void> removeItem(CartItem targetItem) async {
    _items.removeWhere((item) => _isSameIdentity(item, targetItem));
    await _persistCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items = [];
    await _persistCart();
    notifyListeners();
  }

  int _findItemIndex(CartItem targetItem) {
    return _items.indexWhere((item) => _isSameIdentity(item, targetItem));
  }

  bool _isSameIdentity(CartItem a, CartItem b) {
    return a.isSameVariant(
      productId: b.product.id,
      size: b.selectedSize,
      color: b.selectedColor,
    );
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_cartStorageKey, encoded);
  }
}

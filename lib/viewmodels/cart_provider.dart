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
      (sum, item) => sum + (item.unitPrice * item.quantity),
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
    double? unitPrice,
    int quantity = 1,
  }) async {
    final resolvedUnitPrice = unitPrice ?? product.priceForVariant(size);
    final existingIndex = _items.indexWhere(
      (item) => item.isSameVariant(productId: product.id, size: size, color: color),
    );

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
        unitPrice: resolvedUnitPrice,
      );
    } else {
      _items.add(
        CartItem(
          product: product,
          selectedSize: size,
          selectedColor: color,
          unitPrice: resolvedUnitPrice,
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

  Future<void> clearSelectedItems() async {
    _items = _items.where((item) => !item.isSelected).toList(growable: true);
    await _persistCart();
    notifyListeners();
  }

  Future<void> updateItemVariant({
    required CartItem targetItem,
    required String newSize,
    required String newColor,
  }) async {
    final currentIndex = _findItemIndex(targetItem);
    if (currentIndex == -1) return;

    final currentItem = _items[currentIndex];
    final normalizedSize = newSize.trim().isEmpty ? 'Mặc định' : newSize.trim();
    final normalizedColor = newColor.trim().isEmpty ? 'Mặc định' : newColor.trim();
    final newUnitPrice = currentItem.product.priceForVariant(normalizedSize);

    if (currentItem.selectedSize == normalizedSize &&
        currentItem.selectedColor == normalizedColor) {
      if (currentItem.unitPrice != newUnitPrice) {
        _items[currentIndex] = currentItem.copyWith(unitPrice: newUnitPrice);
        await _persistCart();
        notifyListeners();
      }
      return;
    }

    final duplicateIndex = _items.indexWhere(
      (item) =>
          item.product.id == currentItem.product.id &&
          item.selectedSize == normalizedSize &&
          item.selectedColor == normalizedColor,
    );

    if (duplicateIndex != -1 && duplicateIndex != currentIndex) {
      final duplicate = _items[duplicateIndex];
      _items[duplicateIndex] = duplicate.copyWith(
        quantity: duplicate.quantity + currentItem.quantity,
        unitPrice: newUnitPrice,
        isSelected: duplicate.isSelected || currentItem.isSelected,
      );
      _items.removeAt(currentIndex);
    } else {
      _items[currentIndex] = currentItem.copyWith(
        selectedSize: normalizedSize,
        selectedColor: normalizedColor,
        unitPrice: newUnitPrice,
      );
    }

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

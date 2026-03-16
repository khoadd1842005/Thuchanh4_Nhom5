import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/fake_store_product_service.dart';
import '../services/product_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({ProductService? productService})
      : _productService = productService ?? FakeStoreProductService();

  final ProductService _productService;
  List<Product> _products = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _errorMessage;
  static const int _pageSize = 20;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (_isLoading) return;

    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _products = [];
      _errorMessage = null;
    }

    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newProducts = await _productService.fetchProducts(page: _currentPage, limit: _pageSize);

      if (isRefresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _currentPage++;
      _hasMore = newProducts.length == _pageSize;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách sản phẩm. Vui lòng thử lại.';
    }

    _isLoading = false;
    notifyListeners();
  }
}

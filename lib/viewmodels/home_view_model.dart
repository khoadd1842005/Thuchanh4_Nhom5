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
  String _searchQuery = '';
  static const int _pageSize = 20;

  List<Product> get products => _products;
  List<Product> get displayedProducts {
    if (_searchQuery.isEmpty) return _products;

    return _products.where((product) {
      final name = product.name.toLowerCase();
      final category = product.category.toLowerCase();
      final description = product.description.toLowerCase();
      return name.contains(_searchQuery) ||
          category.contains(_searchQuery) ||
          description.contains(_searchQuery);
    }).toList(growable: false);
  }
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.isNotEmpty;

  void setSearchQuery(String value) {
    final nextQuery = value.trim().toLowerCase();
    if (nextQuery == _searchQuery) return;
    _searchQuery = nextQuery;
    notifyListeners();
  }

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
    // Avoid rebuilding the whole product grid while paginating;
    // list updates will notify at the end of fetch.
    if (isRefresh || _products.isEmpty) {
      notifyListeners();
    }

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
      _errorMessage = 'Không tìm thấy sản phẩm.';
    }

    _isLoading = false;
    notifyListeners();
  }
}

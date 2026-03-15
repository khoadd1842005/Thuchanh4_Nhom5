import 'package:flutter/material.dart';
import '../models/product.dart';

class HomeViewModel extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (_isLoading) return;

    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _products = [];
    }

    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    // Giả lập gọi API
    await Future.delayed(const Duration(seconds: 2));

    List<Product> newProducts = List.generate(10, (index) {
      int id = (_currentPage - 1) * 10 + index;
      return Product(
        id: id.toString(),
        name: 'Sản phẩm $id - Tên sản phẩm rất dài để test hiển thị 2 dòng...',
        price: 150000.0 + (id * 1000),
        originalPrice: 300000.0,
        imageUrl: 'https://picsum.photos/200/200?random=$id',
        images: ['https://picsum.photos/500/500?random=$id'],
        description: 'Mô tả chi tiết cho sản phẩm $id. Đây là một đoạn văn bản dài để kiểm tra tính năng xem thêm/thu gọn.',
        category: 'Thời trang',
        soldCount: 1200 + id,
        isMall: id % 3 == 0,
        isFavorite: id % 2 == 0,
        discount: 50,
      );
    });

    if (isRefresh) {
      _products = newProducts;
    } else {
      _products.addAll(newProducts);
    }

    _currentPage++;
    if (_currentPage > 5) {
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }
}

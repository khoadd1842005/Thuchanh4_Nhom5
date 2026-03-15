import '../models/product.dart';

abstract class ProductService {
  Future<List<Product>> fetchProducts({required int page, int limit = 10});
}

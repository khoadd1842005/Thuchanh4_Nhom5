import '../models/product.dart';
import '../models/product_review.dart';

abstract class ProductService {
  Future<List<Product>> fetchProducts({required int page, int limit = 10});
  Future<List<ProductReview>> fetchProductReviews({required String productId});
}

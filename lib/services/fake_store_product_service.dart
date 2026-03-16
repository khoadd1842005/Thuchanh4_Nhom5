import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/product_review.dart';
import 'product_service.dart';

class FakeStoreProductService implements ProductService {
  static const String _baseUrl = 'https://dummyjson.com/products';
  static const double _usdToVndRate = 26000;
  final http.Client _httpClient;

  FakeStoreProductService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  @override
  Future<List<Product>> fetchProducts({required int page, int limit = 10}) async {
    final skip = (page - 1) * limit;
    final endpoint = Uri.parse('$_baseUrl?limit=$limit&skip=$skip');
    final response = await _httpClient.get(endpoint);

    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected product response format.');
    }

    final products = decoded['products'];
    if (products is! List) {
      throw Exception('Missing products field in response.');
    }

    return products.whereType<Map<String, dynamic>>().map(_mapDummyJsonToProduct).toList(growable: false);
  }

  @override
  Future<List<ProductReview>> fetchProductReviews({required String productId}) async {
    final endpoint = Uri.parse('$_baseUrl/$productId');
    final response = await _httpClient.get(endpoint);

    if (response.statusCode != 200) {
      throw Exception('Failed to load product reviews: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected product detail response format.');
    }

    final reviews = decoded['reviews'];
    if (reviews is! List) {
      return const [];
    }

    return reviews
        .whereType<Map>()
        .map((review) => ProductReview.fromJson(Map<String, dynamic>.from(review)))
        .toList(growable: false);
  }

  Product _mapDummyJsonToProduct(Map<String, dynamic> json) {
    final productId = (json['id'] as num?)?.toInt() ?? 0;
    final usdPrice = (json['price'] as num?)?.toDouble() ?? 0;
    final price = (usdPrice * _usdToVndRate).roundToDouble();
    final discountPercentage = (json['discountPercentage'] as num?)?.toDouble();
    final images = (json['images'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(growable: false);
    final category = (json['category'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final rating = (json['rating'] as num?)?.toDouble() ?? 0;
    final stock = (json['stock'] as num?)?.toInt() ?? 0;

    final classification = _buildClassification(
      json: json,
      category: category,
      title: title,
      productId: productId,
    );

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['title'] ?? '').toString(),
      price: price,
      originalPrice: (discountPercentage != null && discountPercentage > 0)
          ? price / (1 - (discountPercentage / 100))
          : null,
      imageUrl: (json['thumbnail'] ?? '').toString(),
      images: images.isNotEmpty ? images : [(json['thumbnail'] ?? '').toString()],
      description: (json['description'] ?? '').toString(),
      category: category,
      rating: rating,
      soldCount: stock,
      sizes: classification.sizes,
      colors: classification.colors,
      isMall: rating >= 4.4,
      isFavorite: rating >= 4.0,
      discount: discountPercentage?.round(),
    );
  }

  _ProductClassification _buildClassification({
    required Map<String, dynamic> json,
    required String category,
    required String title,
    required int productId,
  }) {
    final normalized = category.toLowerCase();
    final detectedColors = _filterColorsForCategory(
      _extractColorsFromText(json, title),
      normalized,
    );

    if (_isFashionCategory(normalized)) {
      final sizes = _pickBySeed(
        const ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
        seed: productId + title.length,
        minCount: 3,
        maxCount: 5,
      );
      final colors = detectedColors.isNotEmpty
          ? detectedColors
          : _pickBySeed(
              const ['Đen', 'Trắng', 'Navy', 'Xám', 'Be', 'Nâu', 'Xanh rêu', 'Đỏ rượu'],
              seed: productId * 3,
              minCount: 2,
              maxCount: 4,
            );
      return _ProductClassification(sizes: sizes, colors: colors);
    }

    if (normalized.contains('shoe')) {
      final sizes = _pickBySeed(
        const ['38', '39', '40', '41', '42', '43'],
        seed: productId,
        minCount: 4,
        maxCount: 5,
      );
      final colors = detectedColors.isNotEmpty
          ? detectedColors
          : _pickBySeed(
              const ['Đen', 'Trắng', 'Xám', 'Navy', 'Đỏ', 'Xanh lá'],
              seed: productId + 11,
              minCount: 2,
              maxCount: 3,
            );
      return _ProductClassification(sizes: sizes, colors: colors);
    }

    if (normalized.contains('smartphone') ||
        normalized.contains('laptop') ||
        normalized.contains('tablet') ||
        normalized.contains('mobile-accessories')) {
      final storageVariants = _pickBySeed(
        const ['64GB', '128GB', '256GB', '512GB'],
        seed: productId,
        minCount: 2,
        maxCount: 3,
      );
      final colors = detectedColors.isNotEmpty
          ? detectedColors
          : _pickBySeed(
              const ['Đen', 'Bạc', 'Titan', 'Graphite', 'Xanh dương', 'Vàng'],
              seed: productId * 5,
              minCount: 2,
              maxCount: 3,
            );
      return _ProductClassification(sizes: storageVariants, colors: colors);
    }

    if (normalized.contains('beauty') || normalized.contains('skin-care')) {
      final tones = _pickBySeed(
        const ['Nude', 'Hồng đất', 'Đỏ berry', 'Cam đào', 'Nâu mocha', 'Hồng'],
        seed: productId,
        minCount: 2,
        maxCount: 3,
      );
      final colors = detectedColors.isNotEmpty ? detectedColors : tones;
      return _ProductClassification(sizes: const ['Mini', 'Full size'], colors: colors);
    }

    if (normalized.contains('fragrances')) {
      final mlFromTitle = _extractVolume(title);
      final sizes = mlFromTitle != null ? [mlFromTitle] : const ['30ml', '50ml', '100ml'];
      return _ProductClassification(
        sizes: sizes,
        colors: const [],
      );
    }

    if (normalized.contains('furniture') ||
        normalized.contains('home-decoration') ||
        normalized.contains('kitchen-accessories')) {
      final sizes = _pickBySeed(
        const ['Nhỏ', 'Vừa', 'Lớn'],
        seed: productId,
        minCount: 2,
        maxCount: 3,
      );
      final colors = detectedColors.isNotEmpty
          ? detectedColors
          : _pickBySeed(
              const ['Nâu gỗ', 'Nâu', 'Be', 'Trắng', 'Đen', 'Xám'],
              seed: productId + 9,
              minCount: 2,
              maxCount: 3,
            );
      return _ProductClassification(sizes: sizes, colors: colors);
    }

    if (normalized.contains('watch') ||
        normalized.contains('jewellery') ||
        normalized.contains('accessories') ||
        normalized.contains('bag')) {
      final colors = detectedColors.isNotEmpty
          ? detectedColors
          : _pickBySeed(
              const ['Bạc', 'Vàng', 'Rose Gold', 'Đen', 'Nâu da', 'Navy'],
              seed: productId,
              minCount: 2,
              maxCount: 3,
            );
      return _ProductClassification(sizes: const [], colors: colors);
    }

    if (normalized.contains('groceries')) {
      final pack = _extractPackSize(title);
      final sizes = pack != null
          ? [pack]
          : _pickBySeed(
              const ['250g', '500g', '1kg'],
              seed: productId,
              minCount: 1,
              maxCount: 2,
            );
      return _ProductClassification(sizes: sizes, colors: const []);
    }

    final genericSizes = _pickBySeed(
      const ['Nhỏ', 'Vừa', 'Lớn'],
      seed: productId + 3,
      minCount: 1,
      maxCount: 2,
    );
    final genericColors = detectedColors.isNotEmpty
        ? detectedColors
        : _pickBySeed(
            const ['Đen', 'Trắng', 'Xám', 'Xanh dương'],
            seed: productId + 7,
            minCount: 2,
            maxCount: 3,
          );
    return _ProductClassification(sizes: genericSizes, colors: genericColors);
  }

  bool _isFashionCategory(String normalizedCategory) {
    return normalizedCategory.contains('shirt') ||
        normalizedCategory.contains('dress') ||
        normalizedCategory.contains('top') ||
        normalizedCategory.contains('mens') ||
        normalizedCategory.contains('womens');
  }

  List<String> _extractColorsFromText(Map<String, dynamic> json, String title) {
    final tags = (json['tags'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().toLowerCase())
        .join(' ');
    final searchText = '${title.toLowerCase()} $tags';

    final keywordRules = <_ColorKeywordRule>[
      _ColorKeywordRule(pattern: RegExp(r'\bspace\s?gray\b', caseSensitive: false), color: 'Xám không gian'),
      _ColorKeywordRule(pattern: RegExp(r'\brose\s?gold\b', caseSensitive: false), color: 'Rose Gold'),
      _ColorKeywordRule(pattern: RegExp(r'\bmidnight\b', caseSensitive: false), color: 'Đen'),
      _ColorKeywordRule(pattern: RegExp(r'\bgraphite\b', caseSensitive: false), color: 'Graphite'),
      _ColorKeywordRule(pattern: RegExp(r'\btitanium\b', caseSensitive: false), color: 'Titan'),
      _ColorKeywordRule(pattern: RegExp(r'\bcharcoal\b', caseSensitive: false), color: 'Xám đậm'),
      _ColorKeywordRule(pattern: RegExp(r'\bivory\b', caseSensitive: false), color: 'Kem'),
      _ColorKeywordRule(pattern: RegExp(r'\bkhaki\b', caseSensitive: false), color: 'Khaki'),
      _ColorKeywordRule(pattern: RegExp(r'\bbeige\b', caseSensitive: false), color: 'Be'),
      _ColorKeywordRule(pattern: RegExp(r'\bcream\b', caseSensitive: false), color: 'Kem'),
      _ColorKeywordRule(pattern: RegExp(r'\bnavy\b', caseSensitive: false), color: 'Xanh navy'),
      _ColorKeywordRule(pattern: RegExp(r'\bolive\b', caseSensitive: false), color: 'Xanh rêu'),
      _ColorKeywordRule(pattern: RegExp(r'\bgreen\b', caseSensitive: false), color: 'Xanh lá'),
      _ColorKeywordRule(pattern: RegExp(r'\bblue\b', caseSensitive: false), color: 'Xanh dương'),
      _ColorKeywordRule(pattern: RegExp(r'\bred\b', caseSensitive: false), color: 'Đỏ'),
      _ColorKeywordRule(pattern: RegExp(r'\bburgundy\b', caseSensitive: false), color: 'Đỏ rượu'),
      _ColorKeywordRule(pattern: RegExp(r'\bpink\b', caseSensitive: false), color: 'Hồng'),
      _ColorKeywordRule(pattern: RegExp(r'\bbrown\b', caseSensitive: false), color: 'Nâu'),
      _ColorKeywordRule(pattern: RegExp(r'\btan\b', caseSensitive: false), color: 'Nâu da'),
      _ColorKeywordRule(pattern: RegExp(r'\bgray\b|\bgrey\b', caseSensitive: false), color: 'Xám'),
      _ColorKeywordRule(pattern: RegExp(r'\bblack\b', caseSensitive: false), color: 'Đen'),
      _ColorKeywordRule(pattern: RegExp(r'\bwhite\b', caseSensitive: false), color: 'Trắng'),
      _ColorKeywordRule(pattern: RegExp(r'\bsilver\b', caseSensitive: false), color: 'Bạc'),
      _ColorKeywordRule(pattern: RegExp(r'\bgold\b', caseSensitive: false), color: 'Vàng'),
      _ColorKeywordRule(pattern: RegExp(r'\bpurple\b', caseSensitive: false), color: 'Tím'),
      _ColorKeywordRule(pattern: RegExp(r'\bamber\b', caseSensitive: false), color: 'Hổ phách'),
      _ColorKeywordRule(pattern: RegExp(r'\btransparent\b|\bclear\b', caseSensitive: false), color: 'Trong suốt'),
      _ColorKeywordRule(pattern: RegExp(r'\bđen\b', caseSensitive: false), color: 'Đen'),
      _ColorKeywordRule(pattern: RegExp(r'\btrắng\b', caseSensitive: false), color: 'Trắng'),
      _ColorKeywordRule(pattern: RegExp(r'\bxám\b', caseSensitive: false), color: 'Xám'),
      _ColorKeywordRule(pattern: RegExp(r'\bbạc\b', caseSensitive: false), color: 'Bạc'),
      _ColorKeywordRule(pattern: RegExp(r'\bvàng\b', caseSensitive: false), color: 'Vàng'),
      _ColorKeywordRule(pattern: RegExp(r'\bnâu\b', caseSensitive: false), color: 'Nâu'),
      _ColorKeywordRule(pattern: RegExp(r'\bxanh\s?navy\b', caseSensitive: false), color: 'Xanh navy'),
      _ColorKeywordRule(pattern: RegExp(r'\bxanh\s?rêu\b', caseSensitive: false), color: 'Xanh rêu'),
      _ColorKeywordRule(pattern: RegExp(r'\bxanh\s?lá\b', caseSensitive: false), color: 'Xanh lá'),
      _ColorKeywordRule(pattern: RegExp(r'\bxanh\s?dương\b|\bxanh\b', caseSensitive: false), color: 'Xanh dương'),
      _ColorKeywordRule(pattern: RegExp(r'\bhồng\b', caseSensitive: false), color: 'Hồng'),
      _ColorKeywordRule(pattern: RegExp(r'\bđỏ\b', caseSensitive: false), color: 'Đỏ'),
      _ColorKeywordRule(pattern: RegExp(r'\bbe\b', caseSensitive: false), color: 'Be'),
      _ColorKeywordRule(pattern: RegExp(r'\bkem\b', caseSensitive: false), color: 'Kem'),
    ];

    final detected = <String>[];
    for (final rule in keywordRules) {
      if (rule.pattern.hasMatch(searchText)) {
        detected.add(rule.color);
      }
    }

    return detected.toSet().toList(growable: false);
  }

  List<String> _filterColorsForCategory(
    List<String> detectedColors,
    String normalizedCategory,
  ) {
    if (detectedColors.isEmpty) {
      return const [];
    }

    if (normalizedCategory.contains('fragrances') || normalizedCategory.contains('groceries')) {
      return const [];
    }

    Set<String> palette;

    if (_isFashionCategory(normalizedCategory) || normalizedCategory.contains('shoe')) {
      palette = {
        'Đen', 'Trắng', 'Xám', 'Xám đậm', 'Be', 'Kem', 'Nâu', 'Nâu da', 'Khaki',
        'Xanh navy', 'Xanh dương', 'Xanh lá', 'Xanh rêu', 'Đỏ', 'Đỏ rượu', 'Hồng', 'Tím',
      };
    } else if (normalizedCategory.contains('smartphone') ||
        normalizedCategory.contains('laptop') ||
        normalizedCategory.contains('tablet') ||
        normalizedCategory.contains('mobile-accessories')) {
      palette = {
        'Đen', 'Trắng', 'Xám', 'Xám không gian', 'Graphite', 'Titan', 'Bạc', 'Vàng',
        'Rose Gold', 'Xanh dương', 'Xanh navy', 'Tím',
      };
    } else if (normalizedCategory.contains('beauty') || normalizedCategory.contains('skin-care')) {
      palette = {
        'Nude', 'Hồng đất', 'Đỏ berry', 'Cam đào', 'Nâu mocha', 'Hồng', 'Đỏ',
        'Be', 'Kem', 'Nâu',
      };
    } else if (normalizedCategory.contains('furniture') ||
        normalizedCategory.contains('home-decoration') ||
        normalizedCategory.contains('kitchen-accessories')) {
      palette = {
        'Nâu gỗ', 'Nâu', 'Nâu da', 'Be', 'Kem', 'Trắng', 'Đen', 'Xám', 'Xám đậm',
      };
    } else if (normalizedCategory.contains('watch') ||
        normalizedCategory.contains('jewellery') ||
        normalizedCategory.contains('accessories') ||
        normalizedCategory.contains('bag')) {
      palette = {
        'Bạc', 'Vàng', 'Rose Gold', 'Đen', 'Nâu', 'Nâu da', 'Trắng', 'Xám', 'Xanh navy',
      };
    } else {
      palette = {
        'Đen', 'Trắng', 'Xám', 'Be', 'Kem', 'Nâu', 'Xanh dương', 'Xanh navy', 'Xanh lá', 'Đỏ', 'Hồng', 'Vàng', 'Bạc',
      };
    }

    return detectedColors.where(palette.contains).toSet().toList(growable: false);
  }

  String? _extractVolume(String title) {
    final match = RegExp(r'(\d+\s?(ml|l))', caseSensitive: false).firstMatch(title);
    return match?.group(1)?.toLowerCase();
  }

  String? _extractPackSize(String title) {
    final match = RegExp(r'(\d+\s?(g|kg|ml|l|pcs))', caseSensitive: false).firstMatch(title);
    return match?.group(1)?.toLowerCase();
  }

  List<String> _pickBySeed(
    List<String> source, {
    required int seed,
    required int minCount,
    required int maxCount,
  }) {
    if (source.isEmpty) {
      return const [];
    }

    final safeMin = minCount.clamp(1, source.length);
    final safeMax = maxCount.clamp(safeMin, source.length);
    final count = safeMin + (seed.abs() % (safeMax - safeMin + 1));
    final start = seed.abs() % source.length;

    final picked = <String>[];
    for (var i = 0; i < count; i++) {
      picked.add(source[(start + i) % source.length]);
    }

    return picked.toSet().toList(growable: false);
  }
}

class _ProductClassification {
  final List<String> sizes;
  final List<String> colors;

  const _ProductClassification({required this.sizes, required this.colors});
}

class _ColorKeywordRule {
  final RegExp pattern;
  final String color;

  const _ColorKeywordRule({required this.pattern, required this.color});
}

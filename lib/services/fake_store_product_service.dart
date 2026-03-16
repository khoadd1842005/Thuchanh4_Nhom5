import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'product_service.dart';

class FakeStoreProductService implements ProductService {
  static const String _baseUrl = 'https://dummyjson.com/products';
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

  Product _mapDummyJsonToProduct(Map<String, dynamic> json) {
    final productId = (json['id'] as num?)?.toInt() ?? 0;
    final price = (json['price'] as num?)?.toDouble() ?? 0;
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
    final detectedColors = _extractColorsFromText(json, title);

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
              const ['Đen', 'Trắng', 'Nâu', 'Xanh navy', 'Be', 'Đỏ rượu', 'Xám'],
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
              const ['Đen', 'Trắng', 'Xám', 'Nâu'],
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
              const ['Đen', 'Bạc', 'Xám không gian', 'Xanh dương'],
              seed: productId * 5,
              minCount: 2,
              maxCount: 3,
            );
      return _ProductClassification(sizes: storageVariants, colors: colors);
    }

    if (normalized.contains('beauty') || normalized.contains('skin-care')) {
      final tones = _pickBySeed(
        const ['Nude', 'Hồng đất', 'Đỏ berry', 'Cam đào', 'Nâu mocha'],
        seed: productId,
        minCount: 2,
        maxCount: 3,
      );
      return _ProductClassification(sizes: const ['Mini', 'Full size'], colors: tones);
    }

    if (normalized.contains('fragrances')) {
      final mlFromTitle = _extractVolume(title);
      final sizes = mlFromTitle != null ? [mlFromTitle] : const ['30ml', '50ml', '100ml'];
      return _ProductClassification(
        sizes: sizes,
        colors: const ['Trong suốt', 'Hổ phách'],
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
              const ['Nâu gỗ', 'Trắng', 'Đen', 'Xám xi măng'],
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
              const ['Bạc', 'Vàng', 'Rose Gold', 'Đen'],
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

    final keywordMap = <String, String>{
      'black': 'Đen',
      'white': 'Trắng',
      'blue': 'Xanh dương',
      'navy': 'Xanh navy',
      'red': 'Đỏ',
      'green': 'Xanh lá',
      'pink': 'Hồng',
      'brown': 'Nâu',
      'gray': 'Xám',
      'grey': 'Xám',
      'silver': 'Bạc',
      'gold': 'Vàng',
      'beige': 'Be',
      'purple': 'Tím',
    };

    final detected = <String>[];
    for (final entry in keywordMap.entries) {
      if (searchText.contains(entry.key)) {
        detected.add(entry.value);
      }
    }

    return detected.toSet().toList(growable: false);
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

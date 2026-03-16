class Product {
  static const double _usdToVndRate = 26000;

  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> images;
  final String description;
  final String category;
  final double rating;
  final int soldCount;
  final List<String> sizes;
  final List<String> colors;
  final bool isMall;
  final bool isFavorite;
  final int? discount;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.images,
    required this.description,
    required this.category,
    this.rating = 0.0,
    this.soldCount = 0,
    this.sizes = const [],
    this.colors = const [],
    this.isMall = false,
    this.isFavorite = false,
    this.discount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      images: (json['images'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(growable: false),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      sizes: (json['sizes'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(growable: false),
      colors: (json['colors'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(growable: false),
      isMall: json['isMall'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      discount: (json['discount'] as num?)?.toInt(),
    );
  }

  factory Product.fromFakeStoreJson(Map<String, dynamic> json) {
    final usdPrice = (json['price'] as num?)?.toDouble() ?? 0;
    final price = (usdPrice * _usdToVndRate).roundToDouble();
    final ratingObject = json['rating'];
    final rating = ratingObject is Map<String, dynamic>
        ? (ratingObject['rate'] as num?)?.toDouble() ?? 0
        : 0.0;
    final sold = ratingObject is Map<String, dynamic>
        ? (ratingObject['count'] as num?)?.toInt() ?? 0
        : 0;

    final category = (json['category'] ?? '').toString();
    final sizes = _defaultSizes(category);
    final colors = _defaultColors(category);
    const discount = 15;

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['title'] ?? '').toString(),
      price: price,
      originalPrice: price > 0 ? price / (1 - discount / 100) : null,
      imageUrl: (json['image'] ?? '').toString(),
      images: [(json['image'] ?? '').toString()],
      description: (json['description'] ?? '').toString(),
      category: category,
      rating: rating,
      soldCount: sold,
      sizes: sizes,
      colors: colors,
      isMall: rating >= 4.2,
      isFavorite: rating >= 4.0,
      discount: discount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'images': images,
      'description': description,
      'category': category,
      'rating': rating,
      'soldCount': soldCount,
      'sizes': sizes,
      'colors': colors,
      'isMall': isMall,
      'isFavorite': isFavorite,
      'discount': discount,
    };
  }

  double priceForVariant(String selectedSize) {
    final normalized = selectedSize.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'mặc định' || normalized == 'mac dinh') {
      return price;
    }

    final measuredFactor = _factorFromMeasuredSize(normalized);
    if (measuredFactor != null) {
      return (price * measuredFactor).roundToDouble();
    }

    const factorByLabel = <String, double>{
      'xs': 0.90,
      's': 0.95,
      'm': 1.00,
      'l': 1.07,
      'xl': 1.14,
      'xxl': 1.20,
      'nhỏ': 0.90,
      'vừa': 1.00,
      'lớn': 1.12,
      'mini': 0.85,
      'full size': 1.00,
      'tiêu chuẩn': 1.00,
      'tieu chuan': 1.00,
    };

    return (price * (factorByLabel[normalized] ?? 1.0)).roundToDouble();
  }

  double? _factorFromMeasuredSize(String selectedSize) {
    final selectedValue = _toBaseUnit(selectedSize);
    if (selectedValue == null || sizes.isEmpty) return null;

    final allValues = sizes
        .map((s) => _toBaseUnit(s.trim().toLowerCase()))
        .whereType<double>()
        .toList(growable: false);

    if (allValues.isEmpty) return null;

    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return null;

    final ratio = selectedValue / maxValue;
    return ratio.clamp(0.5, 1.35);
  }

  double? _toBaseUnit(String raw) {
    final gram = RegExp(r'^(\d+(?:\.\d+)?)\s*g$').firstMatch(raw);
    if (gram != null) {
      return double.tryParse(gram.group(1) ?? '');
    }

    final kilogram = RegExp(r'^(\d+(?:\.\d+)?)\s*kg$').firstMatch(raw);
    if (kilogram != null) {
      final value = double.tryParse(kilogram.group(1) ?? '');
      return value == null ? null : value * 1000;
    }

    final ml = RegExp(r'^(\d+(?:\.\d+)?)\s*ml$').firstMatch(raw);
    if (ml != null) {
      return double.tryParse(ml.group(1) ?? '');
    }

    final liter = RegExp(r'^(\d+(?:\.\d+)?)\s*l$').firstMatch(raw);
    if (liter != null) {
      final value = double.tryParse(liter.group(1) ?? '');
      return value == null ? null : value * 1000;
    }

    final gb = RegExp(r'^(\d+(?:\.\d+)?)\s*gb$').firstMatch(raw);
    if (gb != null) {
      return double.tryParse(gb.group(1) ?? '');
    }

    return null;
  }

  static List<String> _defaultSizes(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('clothing')) {
      return const ['S', 'M', 'L', 'XL'];
    }
    return const ['Tiêu chuẩn'];
  }

  static List<String> _defaultColors(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('jewel')) {
      return const ['Bạc', 'Vàng', 'Rose Gold'];
    }
    return const ['Đen', 'Trắng', 'Xanh Navy'];
  }
}

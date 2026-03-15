class Product {
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
    final price = (json['price'] as num?)?.toDouble() ?? 0;
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

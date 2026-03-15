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
}

class ProductReview {
  final double rating;
  final String comment;
  final DateTime? date;
  final String reviewerName;
  final String reviewerEmail;

  const ProductReview({
    required this.rating,
    required this.comment,
    this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'];
    return ProductReview(
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: (json['comment'] ?? '').toString(),
      date: dateRaw is String && dateRaw.isNotEmpty
          ? DateTime.tryParse(dateRaw)
          : null,
      reviewerName: (json['reviewerName'] ?? json['name'] ?? 'Khach hang').toString(),
      reviewerEmail: (json['reviewerEmail'] ?? json['email'] ?? '').toString(),
    );
  }
}

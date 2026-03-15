import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onFavoriteToggle;

  const ProductCard({Key? key, required this.product, this.onFavoriteToggle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: product),
      child: LayoutBuilder(builder: (context, constraints) {
        final imgHeight = constraints.maxHeight * 0.60;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with overlays (rounded top corners)
              SizedBox(
                height: imgHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    Hero(
                      tag: product.id,
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                        ),
                      ),
                    ),

                    // Favorite (heart) button top-right
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (onFavoriteToggle != null) onFavoriteToggle!();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(product.isFavorite ? 'Đã bỏ yêu thích' : 'Đã thêm vào yêu thích')));
                          },
                          icon: Icon(product.isFavorite ? Icons.favorite : Icons.favorite_border, color: product.isFavorite ? Colors.redAccent : Colors.grey[700], size: 18),
                        ),
                      ),
                    ),

                    // Discount badge
                    if (product.discount != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                          child: Text('Giảm ${product.discount}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.category, style: TextStyle(fontSize: 12, color: Colors.blueGrey[300])),
                    const SizedBox(height: 6),
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(currency.format(product.price), style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 15)),
                        if (product.originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(currency.format(product.originalPrice), style: TextStyle(color: Colors.grey[600], decoration: TextDecoration.lineThrough, fontSize: 12)),
                        ],
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(product.rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(_formatSold(product.soldCount), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatSold(int sold) {
    if (sold >= 1000000) return '${(sold / 1000000).toStringAsFixed(1)}M';
    if (sold >= 1000) return 'Đã bán ${(sold / 1000).toStringAsFixed(sold % 1000 == 0 ? 0 : 1)}k';
    return 'Đã bán $sold';
  }
}


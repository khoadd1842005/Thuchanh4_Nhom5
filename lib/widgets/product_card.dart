import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../viewmodels/cart_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onFavoriteToggle;

  const ProductCard({super.key, required this.product, this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final hasAnyClassification = product.sizes.isNotEmpty || product.colors.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_detail', arguments: product),
      child: LayoutBuilder(builder: (context, constraints) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thành viên 2: Ảnh và các nhãn dán
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Hero(
                      tag: 'product_${product.id}',
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        // TỐI ƯU: Giảm memCacheWidth xuống 400 để hết lag
                        memCacheWidth: 400,
                        maxWidthDiskCache: 600,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: onFavoriteToggle,
                          icon: Icon(
                            product.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: product.isFavorite ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    if (product.isMall)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
                          ),
                          child: const Text('Mall', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (product.discount != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                          child: Text('-${product.discount}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),

              // Nội dung thông tin sản phẩm
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                currency.format(product.price),
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (product.originalPrice != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  currency.format(product.originalPrice),
                                  style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatSold(product.soldCount), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 12, color: Colors.amber),
                                  Text('${product.rating}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () => _showAddToCartSheet(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text(
                                hasAnyClassification ? 'Chọn phân loại' : 'Thêm vào giỏ',
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatSold(int sold) {
    if (sold >= 1000) return 'Đã bán ${(sold / 1000).toStringAsFixed(1)}k';
    return 'Đã bán $sold';
  }

  Future<void> _showAddToCartSheet(BuildContext context) async {
    final hasSizeOptions = product.sizes.isNotEmpty;
    final hasColorOptions = product.colors.isNotEmpty;

    String? selectedSize = hasSizeOptions && product.sizes.length == 1 ? product.sizes.first : null;
    String? selectedColor = hasColorOptions && product.colors.length == 1 ? product.colors.first : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          memCacheWidth: 240,
                          maxWidthDiskCache: 320,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(product.price),
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasSizeOptions) ...[
                    const SizedBox(height: 16),
                    const Text('Kích cỡ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: product.sizes.map((s) => ChoiceChip(
                        label: Text(s),
                        selected: selectedSize == s,
                        onSelected: (_) => setModalState(() => selectedSize = s),
                      )).toList(),
                    ),
                  ],
                  if (hasColorOptions) ...[
                    const SizedBox(height: 16),
                    const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: product.colors.map((c) => ChoiceChip(
                        label: Text(c),
                        selected: selectedColor == c,
                        onSelected: (_) => setModalState(() => selectedColor = c),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      onPressed: () {
                        if ((hasSizeOptions && selectedSize == null) || (hasColorOptions && selectedColor == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn đầy đủ phân loại!')));
                          return;
                        }
                        context.read<CartProvider>().addToCart(
                          product: product,
                          size: selectedSize ?? 'Mặc định',
                          color: selectedColor ?? 'Mặc định',
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng!'), backgroundColor: Colors.green));
                      },
                      child: const Text('XÁC NHẬN'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

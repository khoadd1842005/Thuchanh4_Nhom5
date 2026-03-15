import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../viewmodels/cart_view_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final hasSizeOptions = product.sizes.isNotEmpty;
    final hasColorOptions = product.colors.isNotEmpty;
    final hasAnyClassification = hasSizeOptions || hasColorOptions;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showAddToCartSheet(context),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  if (product.isMall)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                        ),
                        child: const Text(
                          'Mall',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.discount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'Giảm ${product.discount}%',
                            style: const TextStyle(color: Colors.red, fontSize: 10),
                          ),
                        ),
                      if (product.isFavorite)
                        const Text(
                          'Yêu thích',
                          style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(product.price),
                    style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã bán ${product.soldCount > 1000 ? '${(product.soldCount / 1000).toStringAsFixed(1)}k' : product.soldCount}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  if (hasAnyClassification) ...[
                    const SizedBox(height: 2),
                    Text(
                      _buildClassificationSummary(),
                      style: const TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddToCartSheet(context),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text(hasAnyClassification ? 'Chọn phân loại' : 'Thêm vào giỏ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddToCartSheet(BuildContext context) async {
    final hasSizeOptions = product.sizes.isNotEmpty;
    final hasColorOptions = product.colors.isNotEmpty;
    final hasAnyClassification = hasSizeOptions || hasColorOptions;

    String? selectedSize = hasSizeOptions && product.sizes.length == 1 ? product.sizes.first : null;
    String? selectedColor = hasColorOptions && product.colors.length == 1 ? product.colors.first : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
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
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (hasSizeOptions) ...[
                      const SizedBox(height: 16),
                      const Text('Chọn size', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.sizes.map((size) {
                          return ChoiceChip(
                            label: Text(size),
                            selected: selectedSize == size,
                            onSelected: (_) => setModalState(() => selectedSize = size),
                          );
                        }).toList(growable: false),
                      ),
                    ],
                    if (hasColorOptions) ...[
                      const SizedBox(height: 16),
                      const Text('Chọn màu', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.colors.map((color) {
                          return ChoiceChip(
                            label: Text(color),
                            selected: selectedColor == color,
                            onSelected: (_) => setModalState(() => selectedColor = color),
                          );
                        }).toList(growable: false),
                      ),
                    ],
                    if (!hasAnyClassification) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Sản phẩm này không có tùy chọn phân loại.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final missingSize = hasSizeOptions && selectedSize == null;
                          final missingColor = hasColorOptions && selectedColor == null;

                          if (missingSize || missingColor) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  missingSize && missingColor
                                      ? 'Vui lòng chọn đầy đủ size và màu.'
                                      : missingSize
                                          ? 'Vui lòng chọn size.'
                                          : 'Vui lòng chọn màu.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final selectedVariantSize = selectedSize ?? 'Mặc định';
                          final selectedVariantColor = selectedColor ?? 'Mặc định';

                          await sheetContext.read<CartViewModel>().addToCart(
                                product: product,
                                size: selectedVariantSize,
                                color: selectedVariantColor,
                              );

                          if (!sheetContext.mounted) {
                            return;
                          }

                          Navigator.of(sheetContext).pop();

                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm "${product.name}" vào giỏ hàng.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: Text(hasAnyClassification ? 'Thêm vào giỏ hàng' : 'Xác nhận thêm vào giỏ'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _buildClassificationSummary() {
    final parts = <String>[];
    if (product.sizes.isNotEmpty) {
      parts.add('${product.sizes.length} size');
    }
    if (product.colors.isNotEmpty) {
      parts.add('${product.colors.length} màu');
    }
    return 'Phân loại: ${parts.join(' | ')}';
  }
}

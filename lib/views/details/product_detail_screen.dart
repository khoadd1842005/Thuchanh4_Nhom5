import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../viewmodels/cart_provider.dart';
import 'widgets/image_slider.dart';
import 'widgets/bottom_action_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      bottomNavigationBar: BottomActionBar(
        onAddToCart: () => _showVariantSheet(),
        onBuyNow: () => _showVariantSheet(buyNow: true),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: 'product_${widget.product.id}',
              child: ImageSlider(images: widget.product.images.isNotEmpty ? widget.product.images : [widget.product.imageUrl]),
            ),

            // Overlapping white panel with product info
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Rating and sold
                    Row(
                      children: [
                        _buildRatingRow(widget.product.rating),
                        const SizedBox(width: 8),
                        Text(widget.product.rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey[700])),
                        const Spacer(),
                        Text('Đã bán ${widget.product.soldCount}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(currency.format(widget.product.price), style: const TextStyle(color: Colors.red, fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        if (widget.product.originalPrice != null)
                          Text(currency.format(widget.product.originalPrice), style: TextStyle(color: Colors.grey[600], decoration: TextDecoration.lineThrough)),
                        const Spacer(),
                        if (widget.product.discount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                            child: Text('GIẢM ${widget.product.discount}%', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    // Variation selector trigger
                    GestureDetector(
                      onTap: () => _showVariantSheet(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Expanded(child: Text('Chọn kích cỡ, màu sắc', style: TextStyle(fontWeight: FontWeight.w600))),
                            Icon(Icons.keyboard_arrow_right, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text('Mô tả sản phẩm', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    LayoutBuilder(builder: (context, constraints) {
                      final textSpan = TextSpan(text: widget.product.description, style: Theme.of(context).textTheme.bodyMedium);
                      final tp = TextPainter(text: textSpan, maxLines: 5, textDirection: Directionality.of(context));
                      tp.layout(maxWidth: constraints.maxWidth);
                      final didOverflow = tp.didExceedMaxLines;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedCrossFade(
                            firstChild: Text(widget.product.description, maxLines: 5, overflow: TextOverflow.ellipsis),
                            secondChild: Text(widget.product.description),
                            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          if (didOverflow)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(onPressed: () => setState(() => isExpanded = !isExpanded), child: Text(isExpanded ? 'Thu gọn' : 'Xem thêm')),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),

                    // Color selector (if available)
                    if (widget.product.colors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: widget.product.colors.map((c) {
                          final color = Color(int.tryParse(c.replaceAll('#', '0xff')) ?? 0xff000000);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(radius: 14, backgroundColor: color),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVariantSheet({bool buyNow = false}) {
    final sizes = widget.product.sizes.isNotEmpty ? widget.product.sizes : ['S', 'M', 'L'];
    final colors = widget.product.colors.isNotEmpty ? widget.product.colors : ['#000000', '#FFFFFF'];

    final parentContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        int selectedSize = 0;
        int selectedColor = 0;
        int qty = 1;
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(height: 4, width: 40, color: Colors.grey[300])),
                  const SizedBox(height: 8),
                  // Header row: title + close icon
                  Row(
                    children: [
                      Expanded(child: Text('Chọn thuộc tính', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sizes
                  const Text('Kích cỡ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(sizes.length, (i) {
                      return ChoiceChip(
                        label: Text(sizes[i]),
                        selected: selectedSize == i,
                        onSelected: (_) => setState(() => selectedSize = i),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Colors
                  const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(colors.length, (i) {
                      final colorString = colors[i];
                      final color = Color(int.tryParse(colorString.replaceAll('#', '0xff')) ?? 0xff000000);
                      final selected = selectedColor == i;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: EdgeInsets.all(selected ? 3 : 0),
                          decoration: BoxDecoration(border: selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null, shape: BoxShape.circle),
                          child: CircleAvatar(radius: 16, backgroundColor: color),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Quantity
                  Row(
                    children: [
                      const Text('Số lượng', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            IconButton(onPressed: () => setState(() => qty = qty > 1 ? qty - 1 : 1), icon: const Icon(Icons.remove)),
                            Text('$qty'),
                            IconButton(onPressed: () => setState(() => qty = qty + 1), icon: const Icon(Icons.add)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            parentContext.read<CartProvider>().addToCart(
                              product: widget.product,
                              size: sizes[selectedSize],
                              color: colors[selectedColor],
                            );
                            
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text('Thêm thành công'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            
                            if (buyNow) {
                               Navigator.pushNamed(parentContext, '/cart');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(buyNow ? 'Mua ngay' : 'Xác nhận'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildRatingRow(double rating) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      children: List.generate(5, (i) {
        if (i < full) return const Icon(Icons.star, size: 16, color: Colors.amber);
        if (i == full && half) return const Icon(Icons.star_half, size: 16, color: Colors.amber);
        return const Icon(Icons.star_border, size: 16, color: Colors.amber);
      }),
    );
  }
}

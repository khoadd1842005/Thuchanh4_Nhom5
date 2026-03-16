import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/product_review.dart';
import '../../services/fake_store_product_service.dart';
import '../../services/product_service.dart';
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
  late final ProductService _productService;
  late final Future<List<ProductReview>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _productService = FakeStoreProductService();
    _reviewsFuture = _productService.fetchProductReviews(productId: widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final sizeTitle = _sizeLabelForCategory(widget.product.category);
    final showColorInSection = widget.product.colors.isNotEmpty && !_isFoodCategory(widget.product.category);
    final classifyText = showColorInSection
        ? 'Chọn $sizeTitle, màu sắc'
        : 'Chọn $sizeTitle';

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
                            Expanded(child: Text(classifyText, style: const TextStyle(fontWeight: FontWeight.w600))),
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
                    if (showColorInSection) ...[
                      const SizedBox(height: 8),
                      const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: widget.product.colors.map((c) {
                          final color = _resolveColor(c);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(radius: 14, backgroundColor: color),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildReviewSection(),
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
    final hasSizeOptions = widget.product.sizes.isNotEmpty;
    final canShowColor = widget.product.colors.isNotEmpty && !_isFoodCategory(widget.product.category);

    final sizes = hasSizeOptions ? widget.product.sizes : const ['Mặc định'];
    final colors = canShowColor ? widget.product.colors : const <String>[];
    final sizeTitle = _sizeLabelForCategory(widget.product.category);

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
          final selectedSizeValue = sizes[selectedSize];
          final selectedUnitPrice = widget.product.priceForVariant(selectedSizeValue);
          final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
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
                      Text(
                        currency.format(selectedUnitPrice),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sizes
                  Text(sizeTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
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

                  if (canShowColor) ...[
                    const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(colors.length, (i) {
                        final colorString = colors[i];
                        final color = _resolveColor(colorString);
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
                    const SizedBox(height: 6),
                    Text(
                      'Đã chọn màu: ${colors[selectedColor]}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                  ],

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
                              size: selectedSizeValue,
                              color: canShowColor ? colors[selectedColor] : 'Mặc định',
                              unitPrice: selectedUnitPrice,
                              quantity: qty,
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

  bool _isFoodCategory(String category) {
    final normalized = category.toLowerCase();
    return normalized.contains('groceries') ||
        normalized.contains('food') ||
        normalized.contains('drink') ||
        normalized.contains('beverage');
  }

  String _sizeLabelForCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('groceries') || normalized.contains('food')) {
      return 'Khối lượng';
    }
    if (normalized.contains('fragrances') || normalized.contains('beauty')) {
      return 'Dung tích';
    }
    if (normalized.contains('smartphone') ||
        normalized.contains('laptop') ||
        normalized.contains('tablet') ||
        normalized.contains('mobile-accessories')) {
      return 'Phiên bản';
    }
    return 'Kích cỡ';
  }

  Color _resolveColor(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.startsWith('#')) {
      return Color(int.tryParse(normalized.replaceAll('#', '0xff')) ?? 0xff000000);
    }

    const named = <String, Color>{
      'đen': Color(0xFF1E1E1E),
      'trắng': Color(0xFFF5F5F5),
      'xám': Color(0xFF8A8A8A),
      'xám đậm': Color(0xFF4A4A4A),
      'xám không gian': Color(0xFF4B4F56),
      'graphite': Color(0xFF4A4A52),
      'titan': Color(0xFF8A817C),
      'bạc': Color(0xFFC0C0C0),
      'vàng': Color(0xFFD4AF37),
      'rose gold': Color(0xFFB76E79),
      'xanh dương': Color(0xFF2F6DB3),
      'xanh navy': Color(0xFF243B6B),
      'navy': Color(0xFF243B6B),
      'xanh lá': Color(0xFF2E7D32),
      'xanh rêu': Color(0xFF556B2F),
      'đỏ': Color(0xFFC62828),
      'đỏ rượu': Color(0xFF7B1E3A),
      'hồng': Color(0xFFE57399),
      'hồng đất': Color(0xFFB76E79),
      'nude': Color(0xFFD8A48F),
      'cam đào': Color(0xFFF4A688),
      'nâu': Color(0xFF8D6E63),
      'nâu da': Color(0xFF6D4C41),
      'nâu gỗ': Color(0xFF795548),
      'nâu mocha': Color(0xFF6F4E37),
      'be': Color(0xFFE8D8C3),
      'kem': Color(0xFFF1E4CF),
      'khaki': Color(0xFFC3B091),
      'đỏ berry': Color(0xFF8E244D),
      'trong suốt': Color(0xFFE0E0E0),
      'hổ phách': Color(0xFFFFBF00),
    };

    return named[normalized] ?? Colors.grey;
  }

  Widget _buildReviewSection() {
    return FutureBuilder<List<ProductReview>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildReviewContainer(
            child: const Text('Khong tai duoc danh gia tu API.'),
          );
        }

        final reviews = snapshot.data ?? const <ProductReview>[];
        if (reviews.isEmpty) {
          return _buildReviewContainer(
            child: const Text('Sản phẩm hiện chưa có đánh giá.'),
          );
        }

        final avgRating = reviews.fold<double>(0, (sum, r) => sum + r.rating) / reviews.length;

        return _buildReviewContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Đánh giá từ khách hàng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '${avgRating.toStringAsFixed(1)} / 5 (${reviews.length})',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...reviews.take(5).map(_buildReviewItem),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildReviewItem(ProductReview review) {
    final dateText = review.date == null ? '' : DateFormat('dd/MM/yyyy').format(review.date!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName.isEmpty ? 'Khach hang' : review.reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (dateText.isNotEmpty)
                Text(
                  dateText,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _buildRatingRow(review.rating),
          const SizedBox(height: 4),
          Text(review.comment.isEmpty ? 'Khong co noi dung danh gia.' : review.comment),
          if (review.reviewerEmail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                review.reviewerEmail,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

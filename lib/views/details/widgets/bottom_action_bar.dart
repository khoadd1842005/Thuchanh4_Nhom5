import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/cart_view_model.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const BottomActionBar({super.key, this.onAddToCart, this.onBuyNow});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left part: Chat and Cart (1/2 width)
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Chat Icon (Added for Member 2)
                  _buildIconAction(
                    icon: Icons.chat_outlined,
                    label: 'Chat',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng Chat đang phát triển!')),
                      );
                    },
                  ),
                  const VerticalDivider(width: 1, indent: 15, endIndent: 15),
                  // Cart Icon with Badge (Updated logic for Member 4: "number of types")
                  Consumer<CartViewModel>(
                    builder: (context, vm, child) {
                      final typeCount = vm.items.length; // "Số loại sản phẩm"
                      return _buildIconAction(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Giỏ hàng',
                        badgeCount: typeCount,
                        onTap: () => Navigator.pushNamed(context, '/cart'),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right part: Buy buttons (1/2 width)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onAddToCart,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEEEE8),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Thêm vào giỏ',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: onBuyNow,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Mua ngay',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
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

  Widget _buildIconAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.orange, size: 24),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
        ],
      ),
    );
  }
}

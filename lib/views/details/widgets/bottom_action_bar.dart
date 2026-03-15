import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_view_model.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const BottomActionBar({Key? key, this.onAddToCart, this.onBuyNow}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // primary color not required here; using explicit colors for buttons
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Row(
          children: [
            // Left half: Cart icon + badge (smaller)
            Expanded(
              flex: 1,
              child: Consumer<HomeViewModel>(builder: (context, vm, child) {
                final count = vm.cartCount;
                return InkWell(
                  onTap: () => Navigator.pushNamed(context, '/cart'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.black87),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(count > 99 ? '99+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(width: 10),

            // Right half: two action buttons inside this half (wider)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAddToCart,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_shopping_cart, size: 18, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('Thêm vào giỏ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onBuyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                      ),
                      child: const Text('Mua ngay', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
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
}

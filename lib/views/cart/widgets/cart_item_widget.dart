import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/cart_item.dart';
import '../../../viewmodels/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;

  const CartItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Dismissible(
      key: ValueKey('${item.product.id}_${item.selectedSize}_${item.selectedColor}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await context.read<CartProvider>().removeItem(item);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${item.product.name} khỏi giỏ hàng.'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.isSelected,
              onChanged: (value) async {
                await context
                    .read<CartProvider>()
                    .toggleItemSelection(item, value ?? false);
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.product.imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey[200],
                ),
                errorWidget: (_, _, _) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phân loại: ${_buildVariantText(item)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(item.product.price),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _QtyActions(item: item),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildVariantText(CartItem cartItem) {
    final size = cartItem.selectedSize;
    final color = cartItem.selectedColor;

    final hasSize = size.isNotEmpty && size != 'Mặc định' && size != 'Mac dinh';
    final hasColor = color.isNotEmpty && color != 'Mặc định' && color != 'Mac dinh';

    if (hasSize && hasColor) {
      return '$size | $color';
    }
    if (hasSize) {
      return size;
    }
    if (hasColor) {
      return color;
    }
    return 'Mặc định';
  }
}

class _QtyActions extends StatelessWidget {
  final CartItem item;

  const _QtyActions({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(
          icon: Icons.remove,
          onPressed: () async {
            final cartProvider = context.read<CartProvider>();
            if (cartProvider.shouldConfirmRemoveWhenDecrease(item)) {
              final shouldRemove = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text('Bạn có muốn xóa không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  );
                },
              );

              if (shouldRemove == true) {
                await cartProvider.removeItem(item);
              }
              return;
            }

            await cartProvider.decreaseQuantity(item);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '${item.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _QtyButton(
          icon: Icons.add,
          onPressed: () async {
            await context.read<CartProvider>().increaseQuantity(item);
          },
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

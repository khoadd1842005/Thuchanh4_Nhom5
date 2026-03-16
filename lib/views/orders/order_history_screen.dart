import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../viewmodels/order_provider.dart';
import 'widgets/order_tab_bar.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đơn hàng'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: OrderTabBar(),
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return const TabBarView(
              children: [
                _OrderListTab(status: OrderStatus.pending),
                _OrderListTab(status: OrderStatus.delivering),
                _OrderListTab(status: OrderStatus.delivered),
                _OrderListTab(status: OrderStatus.cancelled),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderListTab extends StatelessWidget {
  final OrderStatus status;

  const _OrderListTab({required this.status});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().getOrdersByStatus(status);

    if (orders.isEmpty) {
      return const Center(
        child: Text('Chưa có đơn hàng ở trạng thái này.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn #${order.id.substring(order.id.length - 6)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Địa chỉ: ${order.address}'),
            const SizedBox(height: 4),
            Text('Thanh toán: ${order.paymentMethod}'),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} sản phẩm',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                currency.format(order.totalAmount),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _showOrderDetail(context, order),
                  child: const Text('Xem chi tiết'),
                ),
                const Spacer(),
                if (order.status == OrderStatus.pending ||
                    order.status == OrderStatus.delivering)
                  TextButton(
                    onPressed: () => _confirmCancelOrder(context, order),
                    child: const Text(
                      'Hủy đơn',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết đơn #${order.id.substring(order.id.length - 6)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...order.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.product.name),
                    subtitle: Text(
                      '${item.selectedSize} | ${item.selectedColor} x${item.quantity}',
                    ),
                    trailing: Text(
                      currency.format(item.unitPrice * item.quantity),
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng thanh toán',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currency.format(order.totalAmount),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Địa chỉ: ${order.address}'),
                const SizedBox(height: 4),
                Text('PTTT: ${order.paymentMethod}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmCancelOrder(BuildContext context, Order order) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận hủy đơn'),
          content: const Text('Bạn có chắc muốn hủy đơn hàng này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hủy đơn'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !context.mounted) return;

    await context.read<OrderProvider>().cancelOrder(order.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hủy đơn hàng.')),
    );
  }
}

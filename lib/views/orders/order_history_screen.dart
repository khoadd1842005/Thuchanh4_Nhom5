import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/order_provider.dart';
import '../../models/order.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final tabs = const ['Chờ xác nhận', 'Đang giao', 'Đã giao', 'Đã hủy'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListForStatus(context, OrderStatus.pending),
          _buildListForStatus(context, OrderStatus.shipping),
          _buildListForStatus(context, OrderStatus.delivered),
          _buildListForStatus(context, OrderStatus.cancelled),
        ],
      ),
    );
  }

  Widget _buildListForStatus(BuildContext context, OrderStatus status) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        final list = provider.ordersByStatus(status);
        if (list.isEmpty) {
          return const Center(child: Text('Không có đơn hàng'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) => _orderTile(list[index]),
        );
      },
    );
  }

  Widget _orderTile(Order o) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return ListTile(
      title: Text('Đơn #${o.id} - ${o.status.name}'),
      subtitle: Text('${o.items.length} sản phẩm • ${o.paymentMethod}'),
      trailing: Text(currency.format(o.total)),
      onTap: () => _showOrderDetail(o),
    );
  }

  void _showOrderDetail(Order o) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đơn #${o.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trạng thái: ${o.status.name}'),
              const SizedBox(height: 8),
              Text('Thanh toán: ${o.paymentMethod}'),
              const SizedBox(height: 8),
              Text('Địa chỉ: ${o.address}'),
              const SizedBox(height: 12),
              const Text(
                'Sản phẩm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...o.items.map(
                (ci) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(ci.product.name),
                  subtitle: Text('Số lượng: ${ci.quantity}'),
                  trailing: Text(
                    currency.format(ci.product.price * ci.quantity),
                  ),
                ),
              ),
              const Divider(),
              _detailRow('Tổng tiền hàng', currency.format(o.subTotal)),
              _detailRow('Phí vận chuyển', currency.format(o.shippingFee)),
              _detailRow('Giảm giá', '- ${currency.format(o.discount)}'),
              const Divider(),
              _detailRow(
                'Tổng thanh toán',
                currency.format(o.total),
                isBold: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
}

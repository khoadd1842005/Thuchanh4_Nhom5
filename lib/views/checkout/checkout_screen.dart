import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../viewmodels/cart_provider.dart';
import '../../viewmodels/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;

  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _address = '';
  String _paymentMethod = 'COD';

  static const double shippingFee = 30000;
  static const double discount = 0;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final subTotal = widget.items.fold<double>(
      0,
      (s, i) => s + i.product.price * i.quantity,
    );
    final total = subTotal + shippingFee - discount;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                        ),
                        onSaved: (v) => _name = v?.trim() ?? '',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                        ),
                        keyboardType: TextInputType.phone,
                        onSaved: (v) => _phone = v?.trim() ?? '',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nhập số điện thoại'
                            : null,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Địa chỉ'),
                        onSaved: (v) => _address = v?.trim() ?? '',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nhập địa chỉ'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Phương thức thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      RadioListTile<String>(
                        value: 'Momo',
                        groupValue: _paymentMethod,
                        title: const Text('Momo'),
                        onChanged: (v) =>
                            setState(() => _paymentMethod = v ?? 'Momo'),
                      ),
                      RadioListTile<String>(
                        value: 'COD',
                        groupValue: _paymentMethod,
                        title: const Text('COD (Thanh toán khi nhận hàng)'),
                        onChanged: (v) =>
                            setState(() => _paymentMethod = v ?? 'COD'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Chi tiết giá',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _priceRow('Tổng tiền hàng', currency.format(subTotal)),
                      _priceRow('Phí vận chuyển', currency.format(shippingFee)),
                      _priceRow('Giảm giá', '- ${currency.format(discount)}'),
                      const Divider(),
                      _priceRow(
                        'Tổng thanh toán',
                        currency.format(total),
                        isBold: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: () => _onPlaceOrder(
                context,
                subTotal,
                shippingFee,
                discount,
                total,
              ),
              child: const Text('Đặt hàng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  Future<void> _onPlaceOrder(
    BuildContext context,
    double subTotal,
    double shippingFee,
    double discount,
    double total,
  ) async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    form.save();

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: widget.items,
      subTotal: subTotal,
      shippingFee: shippingFee,
      discount: discount,
      total: total,
      paymentMethod: _paymentMethod,
      address: '$_name, $_phone, $_address',
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );

    // Save order
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.addOrder(order);

    // Clear selected items from cart (requirement: call clearSelectedItems from CartProvider)
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.clearSelectedItems();

    if (!context.mounted) return;

    // Show success dialog then navigate home
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt hàng thành công'),
        content: const Text('Đơn hàng của bạn đã được ghi nhận. Cảm ơn bạn!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );

    // Navigate to home
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}

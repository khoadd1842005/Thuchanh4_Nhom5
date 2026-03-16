import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../viewmodels/cart_provider.dart';
import '../../viewmodels/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'COD';
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isPlacingOrder = false;

  static const double _shippingFee = 30000;
  static const double _discountAmount = 10000;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final selectedItems = cartProvider.selectedItems;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    if (selectedItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: const Center(
          child: Text('Không có sản phẩm nào được chọn để thanh toán.'),
        ),
      );
    }

    final subtotal = selectedItems.fold<double>(
      0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final totalPayment = subtotal + _shippingFee - _discountAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin nhận hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập SĐT' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ nhận hàng', border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 24),
              const Text('Phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'COD',
                    child: Text('Thanh toán khi nhận hàng (COD)'),
                  ),
                  DropdownMenuItem(
                    value: 'Momo',
                    child: Text('Ví MoMo'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _paymentMethod = value);
                },
              ),
              const SizedBox(height: 24),
              const Text('Tóm tắt đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ...selectedItems.map((item) => ListTile(
                title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${item.selectedSize} | ${item.selectedColor} x${item.quantity}'),
                trailing: Text(currencyFormat.format(item.unitPrice * item.quantity)),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền hàng', style: TextStyle(fontSize: 15)),
                  Text(currencyFormat.format(subtotal)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Phí vận chuyển', style: TextStyle(fontSize: 15)),
                  Text(currencyFormat.format(_shippingFee)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giảm giá', style: TextStyle(fontSize: 15)),
                  Text('-${currencyFormat.format(_discountAmount)}', style: const TextStyle(color: Colors.green)),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(currencyFormat.format(totalPayment), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder
                      ? null
                      : () => _handlePlaceOrder(
                            context,
                            selectedItems,
                            totalPayment,
                          ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('ĐẶT HÀNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(
    BuildContext context,
    List<CartItem> selectedItems,
    double totalPayment,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedItems.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    await orderProvider.placeOrder(
      items: List.from(selectedItems),
      totalAmount: totalPayment,
      address: _addressController.text,
      paymentMethod: _paymentMethod,
    );

    await cartProvider.clearSelectedItems();

    if (!context.mounted) return;
    setState(() => _isPlacingOrder = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text('Đặt hàng thành công!\nCảm ơn bạn đã mua sắm.', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('VỀ TRANG CHỦ'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

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
              RadioListTile(
                title: const Text('Thanh toán khi nhận hàng (COD)'),
                value: 'COD',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v.toString()),
              ),
              RadioListTile(
                title: const Text('Ví MoMo'),
                value: 'Momo',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v.toString()),
              ),
              const SizedBox(height: 24),
              const Text('Tóm tắt đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ...cartProvider.selectedItems.map((item) => ListTile(
                title: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${item.selectedSize} | ${item.selectedColor} x${item.quantity}'),
                trailing: Text(currencyFormat.format(item.product.price * item.quantity)),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(fontSize: 16)),
                  Text(currencyFormat.format(cartProvider.totalPrice), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _handlePlaceOrder(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: const Text('ĐẶT HÀNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePlaceOrder(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    // 1. Lưu đơn hàng
    orderProvider.placeOrder(
      items: List.from(cartProvider.selectedItems),
      totalAmount: cartProvider.totalPrice,
      address: _addressController.text,
      paymentMethod: _paymentMethod,
    );

    // 2. Xóa các món đã chọn khỏi giỏ hàng
    for (var item in cartProvider.selectedItems) {
      cartProvider.removeItem(item);
    }

    // 3. Hiện Dialog báo thành công
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text('Đặt hàng thành công!\nCảm ơn bạn đã mua sắm.', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); // Về Home
            },
            child: const Text('VỀ TRANG CHỦ'),
          ),
        ],
      ),
    );
  }
}

import 'product.dart';

class CartItem {
  final Product product;
  final String selectedSize;
  final String selectedColor;
  final double unitPrice;
  final int quantity;
  final bool isSelected;

  const CartItem({
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    required this.unitPrice,
    this.quantity = 1,
    this.isSelected = true,
  });

  CartItem copyWith({
    Product? product,
    String? selectedSize,
    String? selectedColor,
    double? unitPrice,
    int? quantity,
    bool? isSelected,
  }) {
    return CartItem(
      product: product ?? this.product,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'isSelected': isSelected,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = Product.fromJson(json['product'] as Map<String, dynamic>);
    return CartItem(
      product: product,
      selectedSize: (json['selectedSize'] ?? '').toString(),
      selectedColor: (json['selectedColor'] ?? '').toString(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? product.price,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isSelected: json['isSelected'] as bool? ?? true,
    );
  }

  bool isSameVariant({
    required String productId,
    required String size,
    required String color,
  }) {
    return product.id == productId && selectedSize == size && selectedColor == color;
  }
}

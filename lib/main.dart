import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/cart_provider.dart';
import 'viewmodels/home_view_model.dart';
import 'viewmodels/order_provider.dart';
import 'views/cart/cart_screen.dart';
import 'views/home_screen.dart';
import 'views/details/product_detail_screen.dart';
import 'views/checkout/checkout_screen.dart';
import 'views/orders/order_history_screen.dart';
import 'models/product.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()..fetchProducts(isRefresh: true)),
        ChangeNotifierProvider(create: (_) => CartProvider()..loadCart()),
        ChangeNotifierProvider(create: (_) => OrderProvider()..loadOrders()),
      ],
      child: MaterialApp(
        title: 'Thuchanh4',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') return MaterialPageRoute(builder: (_) => const HomeScreen());

          if (settings.name == '/cart') {
            return MaterialPageRoute(builder: (_) => const CartScreen());
          }

          if (settings.name == '/checkout') {
            return MaterialPageRoute(builder: (_) => const CheckoutScreen());
          }

          if (settings.name == '/orders') {
            return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());
          }

          if (settings.name == '/product_detail') {
            final args = settings.arguments;
            if (args is Product) {
              return MaterialPageRoute(builder: (_) => ProductDetailScreen(product: args));
            }
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          }

          return MaterialPageRoute(builder: (_) => const HomeScreen());
        },
      ),
    );
  }
}

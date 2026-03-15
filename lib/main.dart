import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/cart_view_model.dart';
import 'viewmodels/home_view_model.dart';
import 'views/cart_screen.dart';
import 'views/home_screen.dart';
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
        ChangeNotifierProvider(create: (_) => CartViewModel()..loadCart()),
      ],
      child: MaterialApp(
        title: 'Thuchanh4',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Cấu hình Named Routes cho cả nhóm
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/cart': (context) => const CartScreen(),
          // Các thành viên khác sẽ đăng ký route ở đây
          // '/product_detail': (context) => const ProductDetailScreen(),
        },
      ),
    );
  }
}

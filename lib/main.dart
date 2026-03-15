import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/home_view_model.dart';
import 'views/home_screen.dart';
import 'views/details/product_detail_screen.dart';
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
      ],
      child: MaterialApp(
        title: 'Thuchanh4',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Cấu hình Named Routes cho cả nhóm
        initialRoute: '/',
        // Use onGenerateRoute to allow passing arguments (e.g. Product) to detail screens
        onGenerateRoute: (settings) {
          if (settings.name == '/') return MaterialPageRoute(builder: (_) => const HomeScreen());

          if (settings.name == '/product_detail') {
            final args = settings.arguments;
            if (args is Product) {
              return MaterialPageRoute(builder: (_) => ProductDetailScreen(product: args));
            }
            // If no product passed, fallback to HomeScreen
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          }

          // Add other named routes here or fallback
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        },
      ),
    );
  }
}

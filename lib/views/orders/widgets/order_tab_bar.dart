import 'package:flutter/material.dart';

class OrderTabBar extends StatelessWidget {
  const OrderTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white,
      indicatorColor: Colors.orange,
      tabs: const [
        Tab(text: 'Chờ xác nhận'),
        Tab(text: 'Đang giao'),
        Tab(text: 'Đã giao'),
        Tab(text: 'Đã hủy'),
      ],
    );
  }
}

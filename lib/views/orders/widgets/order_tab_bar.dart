import 'package:flutter/material.dart';
import '../../../models/order.dart';

class OrderTabBar extends StatelessWidget {
  final TabController tabController;

  const OrderTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      labelColor: Colors.orange,
      unselectedLabelColor: Colors.grey,
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

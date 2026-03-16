import 'package:flutter/material.dart' hide CarouselController;
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchKey = GlobalKey();
  
  // TỐI ƯU: Dùng ValueNotifier thay vì setState để tránh rebuild toàn màn hình khi cuộn
  final ValueNotifier<bool> _isAppBarPinnedNotifier = ValueNotifier<bool>(false);
  int _currentBannerIndex = 0;

  final List<String> _banners = [
    'https://picsum.photos/800/400?random=11',
    'https://picsum.photos/800/400?random=12',
    'https://picsum.photos/800/400?random=13',
    'https://picsum.photos/800/400?random=14',
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Thời trang', 'icon': Icons.checkroom},
    {'name': 'Điện thoại', 'icon': Icons.phone_android},
    {'name': 'Mỹ phẩm', 'icon': Icons.face},
    {'name': 'Đồ gia dụng', 'icon': Icons.home},
    {'name': 'Giày dép', 'icon': Icons.shopping_bag},
    {'name': 'Đồng hồ', 'icon': Icons.watch},
    {'name': 'Máy tính', 'icon': Icons.computer},
    {'name': 'Thể thao', 'icon': Icons.sports_soccer},
    {'name': 'Sách', 'icon': Icons.book},
    {'name': 'Đồ chơi', 'icon': Icons.toys},
    {'name': 'Sức khỏe', 'icon': Icons.health_and_safety},
    {'name': 'Máy ảnh', 'icon': Icons.camera_alt},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Cập nhật trạng thái App Bar thông qua Notifier (Cực mượt)
    if (_scrollController.offset > 50 && !_isAppBarPinnedNotifier.value) {
      _isAppBarPinnedNotifier.value = true;
    } else if (_scrollController.offset <= 50 && _isAppBarPinnedNotifier.value) {
      _isAppBarPinnedNotifier.value = false;
    }

    // Tự động tải thêm khi cuộn xuống gần cuối
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      context.read<HomeViewModel>().fetchProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _isAppBarPinnedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TỐI ƯU: Background đồng nhất giúp Flutter render layer đơn giản hơn
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeViewModel>().fetchProducts(isRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          // TỐI ƯU: Tăng cacheExtent để Flutter chuẩn bị trước các card, cuộn sẽ mượt hơn
          cacheExtent: 1000, 
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: const SizedBox(height: 10)),
            SliverToBoxAdapter(child: _buildBannerCarousel()),
            SliverToBoxAdapter(child: _buildCategoryGrid()),
            _buildSectionTitle('Gợi ý Hôm nay'),
            _buildProductGrid(),
            _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isAppBarPinnedNotifier,
      builder: (context, isPinned, child) {
        return SliverAppBar(
          pinned: true,
          expandedHeight: 130,
          backgroundColor: isPinned ? Colors.orange : Colors.orange.withValues(alpha: 0.1),
          elevation: isPinned ? 2 : 0,
          title: Text(
            'TH4 - Nhóm 5',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isPinned ? Colors.white : Colors.orange,
              fontSize: 18
            ),
          ),
          actions: [_buildCartIcon(), const SizedBox(width: 8)],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
                  ],
                ),
                child: TextField(
                  key: _searchKey,
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Tìm kiếm sản phẩm...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartIcon() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            if (cart.items.isNotEmpty)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${cart.items.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBannerCarousel() {
    // TỐI ƯU: Tránh dùng Column lồng nhau phức tạp
    return CarouselSlider(
      options: CarouselOptions(
        height: 160,
        autoPlay: true,
        viewportFraction: 0.9,
        enlargeCenterPage: true,
      ),
      items: _banners.map((url) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryGrid() {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_categories[index]['icon'], color: Colors.orange, size: 24),
              ),
              const SizedBox(height: 4),
              Text(_categories[index]['name'], style: const TextStyle(fontSize: 11)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: viewModel.products[index]),
              childCount: viewModel.products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasMore) return const SliverToBoxAdapter(child: SizedBox(height: 50, child: Center(child: Text('Hết rồi!'))));
        return SliverToBoxAdapter(
          child: viewModel.isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
              : const SizedBox(height: 80),
        );
      },
    );
  }
}

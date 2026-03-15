import 'package:flutter/material.dart' hide CarouselController;
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../viewmodels/cart_view_model.dart';
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
  bool _isAutoPrefetching = false;
  int _currentBannerIndex = 0;
  bool _isAppBarPinned = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureInitialScrollableContent();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    if (_scrollController.offset > 50 && !_isAppBarPinned) {
      setState(() => _isAppBarPinned = true);
    } else if (_scrollController.offset <= 50 && _isAppBarPinned) {
      setState(() => _isAppBarPinned = false);
    }

    final position = _scrollController.position;
    const preloadThreshold = 300.0;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - preloadThreshold;
    if (shouldLoadMore) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!mounted) return;
    await context.read<HomeViewModel>().fetchProducts();
  }

  Future<void> _ensureInitialScrollableContent() async {
    if (!mounted || _isAutoPrefetching) return;
    if (!_scrollController.hasClients) return;

    _isAutoPrefetching = true;
    try {
      final viewModel = context.read<HomeViewModel>();
      var attempts = 0;

      while (mounted && attempts < 3) {
        if (viewModel.isLoading || !viewModel.hasMore) break;
        if (_scrollController.position.maxScrollExtent > 0) break;

        attempts++;
        await viewModel.fetchProducts();
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } finally {
      _isAutoPrefetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<HomeViewModel>().fetchProducts(isRefresh: true);
          if (mounted) {
            await _ensureInitialScrollableContent();
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
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
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120, // Tăng lên để đủ chỗ cho tiêu đề định danh
      toolbarHeight: 90,   // Tăng để chứa 2 dòng: Tiêu đề và SearchBar
      backgroundColor: _isAppBarPinned ? Colors.orange : Colors.orange.withValues(alpha: 0.1),
      elevation: 0,
      titleSpacing: 0,
      title: Column(
        children: [
          // Dòng 1: Định danh nhóm (Yêu cầu bắt buộc)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TH4 - Nhóm 5',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _buildCartIcon(),
              ],
            ),
          ),
          // Dòng 2: Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  if (!_isAppBarPinned)
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
                ],
              ),
              child: TextField(
                key: _searchKey,
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 14, color: Colors.black),
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
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.orange.withValues(alpha: 0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    return Consumer<CartViewModel>(
      builder: (context, cartViewModel, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            if (cartViewModel.totalItems > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${cartViewModel.totalItems}',
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
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() => _currentBannerIndex = index);
            },
          ),
          items: _banners.map((url) {
            return Builder(
              builder: (BuildContext context) {
                return Image.network(url, fit: BoxFit.cover, width: MediaQuery.of(context).size.width);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        AnimatedSmoothIndicator(
          activeIndex: _currentBannerIndex,
          count: _banners.length,
          effect: const ScrollingDotsEffect(
            dotWidth: 8,
            dotHeight: 8,
            activeDotColor: Colors.orange,
            dotColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categories[index]['icon'], color: Colors.orange),
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
        padding: const EdgeInsets.all(16.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.products.isEmpty && viewModel.errorMessage != null) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;

              int crossAxisCount;
              if (width >= 1400) {
                crossAxisCount = 6;
              } else if (width >= 1100) {
                crossAxisCount = 5;
              } else if (width >= 850) {
                crossAxisCount = 4;
              } else if (width >= 620) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 2;
              }

              final itemWidth = (width - (crossAxisCount - 1) * 8) / crossAxisCount;
              final targetItemHeight = itemWidth < 180
                  ? 320.0
                  : itemWidth < 230
                      ? 340.0
                      : 360.0;
              final childAspectRatio = itemWidth / targetItemHeight;

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(product: viewModel.products[index]),
                  childCount: viewModel.products.length,
                ),
              );
            },
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
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox(height: 50),
        );
      },
    );
  }
}

import 'package:flutter/material.dart' hide CarouselController;
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isAppBarPinned) {
        setState(() => _isAppBarPinned = true);
      } else if (_scrollController.offset <= 50 && _isAppBarPinned) {
        setState(() => _isAppBarPinned = false);
      }

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<HomeViewModel>().fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFE8),
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeViewModel>().fetchProducts(isRefresh: true),
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
      expandedHeight: 120,
      toolbarHeight: 90,
      backgroundColor: _isAppBarPinned ? Colors.orange : Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              height: 44,
              decoration: BoxDecoration(
                color: _isAppBarPinned ? Colors.orange.withOpacity(0.95) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  if (_isAppBarPinned) BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: TextField(
                key: _searchKey,
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(fontSize: 14, color: _isAppBarPinned ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tìm kiếm sản phẩm...',
                  hintStyle: TextStyle(fontSize: 13, color: _isAppBarPinned ? Colors.white70 : Colors.grey),
                  prefixIcon: Icon(Icons.search, color: _isAppBarPinned ? Colors.white : Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
              colors: [Colors.orange, Colors.orange.withValues(alpha: 0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    return Consumer<HomeViewModel>(builder: (context, vm, child) {
      final count = vm.cartCount;
      return Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            onPressed: () {
              // Navigator.pushNamed(context, '/cart');
            },
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
          if (count > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() => _currentBannerIndex = index);
            },
          ),
          items: _banners.map((url) {
            return Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(url, fit: BoxFit.cover, width: MediaQuery.of(context).size.width),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.18), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('KHUYẾN MÃI XUÂN', style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 12)),
                              SizedBox(height: 6),
                              Text('Mang mùa xuân vào từng bước chân', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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
            activeDotColor: Colors.black,
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
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
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

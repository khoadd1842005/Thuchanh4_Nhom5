import 'dart:async';

import 'package:flutter/material.dart' hide CarouselController;
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/foundation.dart';
import '../viewmodels/cart_provider.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<int> _bannerIndexNotifier = ValueNotifier<int>(0);
  final GlobalKey _searchKey = GlobalKey();
  bool _isAutoPrefetching = false;
  bool _isAppBarPinned = false;
  DateTime? _lastLoadMoreAt;
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    _bannerIndexNotifier.dispose();
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

    final viewModel = context.read<HomeViewModel>();
    if (viewModel.isLoading || !viewModel.hasMore || viewModel.searchQuery.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    if (_lastLoadMoreAt != null && now.difference(_lastLoadMoreAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastLoadMoreAt = now;

    await viewModel.fetchProducts();
  }

  Future<void> _ensureInitialScrollableContent() async {
    if (!mounted || _isAutoPrefetching) return;
    if (!_scrollController.hasClients) return;

    _isAutoPrefetching = true;
    try {
      final viewModel = context.read<HomeViewModel>();
      var attempts = 0;

      while (mounted && attempts < 2) {
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
          cacheExtent: 1200,
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
                onChanged: (value) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                    if (!mounted) return;
                    context.read<HomeViewModel>().setSearchQuery(value);
                  });
                },
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
    return Consumer<CartProvider>(
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
              _bannerIndexNotifier.value = index;
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
        ValueListenableBuilder<int>(
          valueListenable: _bannerIndexNotifier,
          builder: (context, index, _) {
            return AnimatedSmoothIndicator(
              activeIndex: index,
              count: _banners.length,
              effect: const ScrollingDotsEffect(
                dotWidth: 8,
                dotHeight: 8,
                activeDotColor: Colors.orange,
                dotColor: Colors.grey,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final contentMaxWidth = width >= 1400
            ? 1280.0
            : width >= 1100
                ? 1040.0
                : width;

        int crossAxisCount;
        if (width >= 1200) {
          crossAxisCount = 6;
        } else if (width >= 900) {
          crossAxisCount = 5;
        } else if (width >= 700) {
          crossAxisCount = 4;
        } else {
          crossAxisCount = 3;
        }

        const spacing = 12.0;
        final effectiveWidth = contentMaxWidth - 32;
        final itemWidth = (effectiveWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        final iconBoxSize = (itemWidth * 0.58).clamp(34.0, 62.0).toDouble();
        final iconSize = (iconBoxSize * 0.52).clamp(16.0, 28.0).toDouble();
        final categoryFontSize = width >= 1100 ? 13.0 : width >= 760 ? 12.0 : 11.0;
        final rows = (_categories.length / crossAxisCount).ceil();
        final sectionHeight = rows * 96.0 + (rows - 1) * spacing + 20;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: SizedBox(
              height: sectionHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: itemWidth / 96.0,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(iconBoxSize * 0.28),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _categories[index]['icon'],
                          color: Colors.orange,
                          size: iconSize,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _categories[index]['name'],
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: categoryFontSize),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
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
    return Selector<HomeViewModel, List<Product>>(
      selector: (_, viewModel) => viewModel.displayedProducts,
      shouldRebuild: (previous, next) => !listEquals(previous, next),
      builder: (context, displayedProducts, child) {
        final errorMessage = context.select<HomeViewModel, String?>((vm) => vm.errorMessage);

        if (displayedProducts.isEmpty && errorMessage != null) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (displayedProducts.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Không tìm thấy sản phẩm phù hợp',
                  style: TextStyle(color: Colors.grey),
                ),
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
                  (context, index) => ProductCard(product: displayedProducts[index]),
                  childCount: displayedProducts.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
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

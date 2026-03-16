import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageSlider extends StatefulWidget {
  final List<String> images;

  const ImageSlider({super.key, required this.images});

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final PageController _pageController = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasDots = images.length > 1;
        const dotsBlockHeight = 18.0;

        Widget buildImagePager() {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  memCacheWidth: 1400,
                  maxWidthDiskCache: 1800,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 36,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
            ),
          );
        }

        Widget buildDots() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (i) {
              final selected = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          );
        }

        if (constraints.hasBoundedHeight) {
          final showDots = hasDots && constraints.maxHeight >= 200;
          final reserved = showDots ? dotsBlockHeight : 0.0;

          return SizedBox(
            height: constraints.maxHeight,
            width: double.infinity,
            child: Column(
              children: [
                Expanded(child: buildImagePager()),
                if (showDots) ...[
                  const SizedBox(height: 10),
                  buildDots(),
                ],
                if (reserved > 0)
                  const SizedBox.shrink(),
              ],
            ),
          );
        }

        final imageHeight = (constraints.maxWidth / 1.1).clamp(180.0, 520.0);
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: imageHeight, child: buildImagePager()),
              if (hasDots) ...[
                const SizedBox(height: 10),
                buildDots(),
              ],
            ],
          ),
        );
      },
    );
  }
}

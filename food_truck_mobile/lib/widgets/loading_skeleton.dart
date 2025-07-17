import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });
  
  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[300]!.withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

// Food truck card skeleton
class FoodTruckCardSkeleton extends StatelessWidget {
  const FoodTruckCardSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            SkeletonLoader(
              width: double.infinity,
              height: 180,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            
            // Title skeleton
            const SkeletonLoader(
              width: 200,
              height: 24,
            ),
            const SizedBox(height: 8),
            
            // Description skeleton
            const SkeletonLoader(
              width: double.infinity,
              height: 16,
            ),
            const SizedBox(height: 4),
            const SkeletonLoader(
              width: 250,
              height: 16,
            ),
            const SizedBox(height: 12),
            
            // Rating and distance skeleton
            Row(
              children: [
                const SkeletonLoader(
                  width: 80,
                  height: 20,
                ),
                const SizedBox(width: 16),
                const SkeletonLoader(
                  width: 60,
                  height: 20,
                ),
                const Spacer(),
                SkeletonLoader(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Menu item skeleton
class MenuItemSkeleton extends StatelessWidget {
  const MenuItemSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image skeleton
            SkeletonLoader(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(
                    width: 150,
                    height: 20,
                  ),
                  SizedBox(height: 4),
                  SkeletonLoader(
                    width: 200,
                    height: 16,
                  ),
                  SizedBox(height: 4),
                  SkeletonLoader(
                    width: 80,
                    height: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Analytics card skeleton
class AnalyticsCardSkeleton extends StatelessWidget {
  const AnalyticsCardSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonLoader(
              width: 120,
              height: 20,
            ),
            SizedBox(height: 8),
            SkeletonLoader(
              width: 80,
              height: 32,
            ),
            SizedBox(height: 16),
            SkeletonLoader(
              width: double.infinity,
              height: 150,
            ),
          ],
        ),
      ),
    );
  }
}

// List skeleton helper
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;
  
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
} 
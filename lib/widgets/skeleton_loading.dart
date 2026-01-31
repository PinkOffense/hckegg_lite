// lib/widgets/skeleton_loading.dart
import 'package:flutter/material.dart';

/// Shimmer animation for loading skeletons
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                0.0,
                (_animation.value + 2) / 4,
                1.0,
              ],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Skeleton placeholder box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for a card item
class SkeletonCard extends StatelessWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SkeletonBox(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 120, height: 16),
                        SizedBox(height: 8),
                        SkeletonBox(width: 80, height: 12),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 60, height: 24, borderRadius: 12),
                ],
              ),
              const Spacer(),
              const SkeletonBox(height: 12),
              const SizedBox(height: 8),
              const SkeletonBox(width: 200, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a list view
class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;

  const SkeletonListView({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 120,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading content',
      child: ListView.separated(
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => SkeletonCard(height: itemHeight),
      ),
    );
  }
}

/// Skeleton for statistics grid
class SkeletonStatsGrid extends StatelessWidget {
  final int columns;
  final int rows;

  const SkeletonStatsGrid({
    super.key,
    this.columns = 2,
    this.rows = 2,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: List.generate(
          columns * rows,
          (_) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SkeletonBox(width: 60, height: 12),
                  SizedBox(height: 12),
                  SkeletonBox(width: 80, height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for chart
class SkeletonChart extends StatelessWidget {
  final double height;

  const SkeletonChart({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 120, height: 20),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    7,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SkeletonBox(
                          height: 40.0 + (i * 15.0) % 80,
                          borderRadius: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full page loading skeleton
class SkeletonPage extends StatelessWidget {
  final bool showStats;
  final bool showChart;
  final int listItemCount;

  const SkeletonPage({
    super.key,
    this.showStats = true,
    this.showChart = true,
    this.listItemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading page content',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (showStats) ...[
              const SkeletonStatsGrid(),
              const SizedBox(height: 16),
            ],
            if (showChart) ...[
              const SkeletonChart(),
              const SizedBox(height: 16),
            ],
            ...List.generate(
              listItemCount,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

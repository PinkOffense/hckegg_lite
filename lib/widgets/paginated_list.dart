// lib/widgets/paginated_list.dart
import 'package:flutter/material.dart';
import 'skeleton_loading.dart';

/// Configuration for pagination
class PaginationConfig {
  final int pageSize;
  final int initialPage;
  final double loadMoreThreshold;

  const PaginationConfig({
    this.pageSize = 20,
    this.initialPage = 0,
    this.loadMoreThreshold = 200.0,
  });
}

/// State holder for paginated data
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PaginatedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }

  bool get isEmpty => items.isEmpty && !isLoading;
  bool get canLoadMore => hasMore && !isLoading && error == null;
}

/// Paginated list view with infinite scroll
class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final Future<void> Function()? onRefresh;
  final bool hasMore;
  final bool isLoading;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final String? error;
  final PaginationConfig config;
  final EdgeInsets padding;
  final Widget? separatorBuilder;
  final ScrollPhysics? physics;
  final String? semanticLabel;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.onRefresh,
    this.hasMore = false,
    this.isLoading = false,
    this.emptyWidget,
    this.errorWidget,
    this.error,
    this.config = const PaginationConfig(),
    this.padding = const EdgeInsets.all(16),
    this.separatorBuilder,
    this.physics,
    this.semanticLabel,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= widget.config.loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;

    setState(() => _isLoadingMore = true);

    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading skeleton on initial load
    if (widget.isLoading && widget.items.isEmpty) {
      return const SkeletonListView();
    }

    // Show error state
    if (widget.error != null && widget.items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  if (widget.onRefresh != null)
                    ElevatedButton.icon(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                ],
              ),
            ),
          );
    }

    // Show empty state
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    // Build the list
    Widget listView = ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          widget.separatorBuilder ?? const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index >= widget.items.length) {
          return _buildLoadingIndicator();
        }

        return widget.itemBuilder(context, widget.items[index], index);
      },
    );

    // Wrap with RefreshIndicator if onRefresh provided
    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    // Add semantics
    if (widget.semanticLabel != null) {
      listView = Semantics(
        label: widget.semanticLabel,
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Semantics(
          label: 'Loading more items',
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

/// Paginated sliver list for use in CustomScrollView
class PaginatedSliverList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final PaginationConfig config;

  const PaginatedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.config = const PaginationConfig(),
  });

  @override
  State<PaginatedSliverList<T>> createState() => _PaginatedSliverListState<T>();
}

class _PaginatedSliverListState<T> extends State<PaginatedSliverList<T>> {
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= widget.items.length) {
            if (widget.hasMore) {
              // Trigger load more when reaching end
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onLoadMore?.call();
              });
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }
          return widget.itemBuilder(context, widget.items[index], index);
        },
        childCount: widget.items.length + (widget.hasMore ? 1 : 0),
      ),
    );
  }
}

/// Helper extension for pagination
extension PaginationHelpers<T> on List<T> {
  /// Paginate a list
  List<T> paginate(int page, int pageSize) {
    final start = page * pageSize;
    if (start >= length) return [];
    final end = (start + pageSize).clamp(0, length);
    return sublist(start, end);
  }

  /// Check if there are more pages
  bool hasMorePages(int currentPage, int pageSize) {
    return (currentPage + 1) * pageSize < length;
  }
}

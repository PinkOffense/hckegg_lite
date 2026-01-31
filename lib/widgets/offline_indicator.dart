// lib/widgets/offline_indicator.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/connectivity_service.dart';
import '../l10n/translations.dart';

/// Widget that shows an offline banner when there's no internet connection
class OfflineIndicator extends StatefulWidget {
  final Widget child;
  final String locale;

  const OfflineIndicator({
    super.key,
    required this.child,
    required this.locale,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final _connectivity = ConnectivityService();
  late StreamSubscription<bool> _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivity.isOnline;
    _subscription = _connectivity.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = (String k) => Translations.of(widget.locale, k);

    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOnline ? 0 : 32,
          child: _isOnline
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.red.shade700,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            color: Colors.white,
                            size: 16,
                            semanticLabel: 'Offline',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t('no_internet'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Mixin to add pull-to-refresh with connectivity check
mixin RefreshablePage<T extends StatefulWidget> on State<T> {
  final ConnectivityService connectivity = ConnectivityService();

  String get refreshLocale;
  Future<void> onRefresh();

  Future<void> handleRefresh() async {
    final isOnline = await connectivity.checkNow();
    if (!isOnline) {
      if (mounted) {
        final t = (String k) => Translations.of(refreshLocale, k);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('no_internet')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    await onRefresh();
  }
}

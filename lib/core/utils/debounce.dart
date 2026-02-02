import 'dart:async';

/// Debounce utility to prevent rapid repeated calls
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Run the action after the delay, cancelling any previous pending action
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose the debouncer
  void dispose() {
    cancel();
  }
}

/// Throttle utility to limit how often an action can be called
class Throttler {
  final Duration delay;
  DateTime? _lastRun;
  bool _isWaiting = false;

  Throttler({this.delay = const Duration(milliseconds: 500)});

  /// Run the action if enough time has passed since the last run
  void run(void Function() action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= delay) {
      _lastRun = now;
      action();
    }
  }

  /// Run action immediately, then ignore subsequent calls until delay passes
  void runImmediate(void Function() action) {
    if (!_isWaiting) {
      _isWaiting = true;
      action();
      Future.delayed(delay, () => _isWaiting = false);
    }
  }
}

/// Mixin for StatefulWidget to add debounced save functionality
/// Prevents double-taps and shows loading state
mixin SaveOperationMixin<T extends StatefulWidget> on State<T> {
  bool _isSaving = false;

  bool get isSaving => _isSaving;

  /// Execute a save operation with loading state management
  /// Returns true if save was successful, false otherwise
  Future<bool> executeSave(Future<void> Function() saveAction) async {
    if (_isSaving) return false;

    setState(() => _isSaving = true);

    try {
      await saveAction();
      return true;
    } catch (e) {
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Execute save with mounted check and optional error callback
  Future<bool> executeSaveWithMountedCheck({
    required Future<void> Function() saveAction,
    void Function(Object error)? onError,
    void Function()? onSuccess,
  }) async {
    if (_isSaving) return false;
    if (!mounted) return false;

    setState(() => _isSaving = true);

    try {
      await saveAction();
      if (mounted) {
        onSuccess?.call();
      }
      return true;
    } catch (e) {
      if (mounted) {
        onError?.call(e);
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app_bootstrap.dart';
import 'app/app_widget.dart';
import 'core/utils/error_handler.dart';

Future<void> main() async {
  // Catch all Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler.logError('FlutterError', details.exception, details.stack);
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Catch async errors not handled by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler.logError('PlatformDispatcher', error, stack);
    return true;
  };

  // Run app in a guarded zone for remaining uncaught errors
  runZonedGuarded(
    () async {
      await bootstrap();
      runApp(const HckEggApp());
    },
    (error, stackTrace) {
      ErrorHandler.logError('ZoneGuard', error, stackTrace);
    },
  );
}

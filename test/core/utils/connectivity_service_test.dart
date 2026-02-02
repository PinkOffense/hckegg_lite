import 'package:flutter_test/flutter_test.dart';
import 'package:hckegg_lite/core/utils/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    late ConnectivityService service;

    setUp(() {
      service = ConnectivityService();
    });

    tearDown(() {
      service.dispose();
    });

    test('is singleton', () {
      final service1 = ConnectivityService();
      final service2 = ConnectivityService();
      expect(identical(service1, service2), true);
    });

    test('starts with online status by default', () {
      expect(service.isOnline, true);
    });

    test('provides connectivity stream', () {
      expect(service.onConnectivityChanged, isA<Stream<bool>>());
    });

    test('checkNow returns current status', () async {
      // On web/test environment, this should return true
      final isOnline = await service.checkNow();
      expect(isOnline, isA<bool>());
    });

    test('startMonitoring starts periodic checks', () {
      // This just verifies the method doesn't throw
      expect(() => service.startMonitoring(), returnsNormally);
    });

    test('stopMonitoring stops checks', () {
      service.startMonitoring();
      expect(() => service.stopMonitoring(), returnsNormally);
    });

    test('dispose cleans up resources', () {
      service.startMonitoring();
      expect(() => service.dispose(), returnsNormally);
    });
  });
}

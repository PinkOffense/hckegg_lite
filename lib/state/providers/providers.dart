// lib/state/providers/providers.dart
// Barrel file for all providers

// Clean Architecture providers
export '../../features/sales/presentation/providers/sale_provider.dart';
export '../../features/expenses/presentation/providers/expense_provider.dart';
export '../../features/health/presentation/providers/vet_provider.dart'; // Also exports VetRecordProvider typedef
export '../../features/feed_stock/presentation/providers/feed_stock_provider.dart';
export '../../features/reservations/presentation/providers/reservation_provider.dart';

// Legacy providers (still needed for some functionality)
export 'egg_provider.dart';
export 'egg_record_provider.dart';

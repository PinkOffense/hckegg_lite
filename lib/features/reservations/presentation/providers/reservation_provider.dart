import 'package:flutter/foundation.dart';

import '../../../../core/core.dart';
import '../../../../models/egg_reservation.dart';
import '../../../../models/egg_sale.dart';
import '../../../sales/domain/domain.dart' as sales;
import '../../../sales/presentation/providers/sale_provider.dart';
import '../../domain/domain.dart';

/// State for the reservations feature
enum ReservationState { initial, loading, loaded, error }

/// Provider for reservations following clean architecture
class ReservationProvider extends ChangeNotifier {
  final GetReservations _getReservations;
  final GetReservationsInRange _getReservationsInRange;
  final CreateReservation _createReservation;
  final UpdateReservation _updateReservation;
  final DeleteReservation _deleteReservation;
  final sales.CreateSale? _createSale;

  ReservationProvider({
    required GetReservations getReservations,
    required GetReservationsInRange getReservationsInRange,
    required CreateReservation createReservation,
    required UpdateReservation updateReservation,
    required DeleteReservation deleteReservation,
    sales.CreateSale? createSale,
  })  : _getReservations = getReservations,
        _getReservationsInRange = getReservationsInRange,
        _createReservation = createReservation,
        _updateReservation = updateReservation,
        _deleteReservation = deleteReservation,
        _createSale = createSale;

  // State
  ReservationState _state = ReservationState.initial;
  ReservationState get state => _state;

  List<EggReservation> _reservations = [];
  List<EggReservation> get reservations => List.unmodifiable(_reservations);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage; // Backward compatibility

  bool get isLoading => _state == ReservationState.loading;
  bool get hasError => _state == ReservationState.error;

  /// Load all reservations
  Future<void> loadReservations() async {
    _state = ReservationState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _getReservations(const NoParams());

    result.fold(
      onSuccess: (data) {
        _reservations = data;
        _state = ReservationState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = ReservationState.error;
      },
    );

    notifyListeners();
  }

  /// Get reservations in date range
  Future<List<EggReservation>> getReservationsInRange(DateTime start, DateTime end) async {
    final result = await _getReservationsInRange(
      GetReservationsInRangeParams(start: start, end: end),
    );
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (_) => [],
    );
  }

  /// Get reservations in range (local filtering)
  List<EggReservation> getReservationsInRangeLocal(DateTime start, DateTime end) {
    final startStr = _toIsoDateString(start);
    final endStr = _toIsoDateString(end);
    return _reservations.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  /// Search reservations by customer name, phone, notes, or quantity
  List<EggReservation> search(String query) {
    if (query.isEmpty) return _reservations;
    final q = query.toLowerCase();
    return _reservations.where((r) {
      final nameMatch = r.customerName?.toLowerCase().contains(q) ?? false;
      final phoneMatch = r.customerPhone?.toLowerCase().contains(q) ?? false;
      final notesMatch = r.notes?.toLowerCase().contains(q) ?? false;
      final dateMatch = r.date.toLowerCase().contains(q);
      final quantityMatch = r.quantity.toString().contains(q);
      return nameMatch || phoneMatch || notesMatch || dateMatch || quantityMatch;
    }).toList();
  }

  String _toIsoDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Save a reservation (create or update)
  Future<void> saveReservation(EggReservation reservation) async {
    _state = ReservationState.loading;
    notifyListeners();

    final Result<EggReservation> result;

    if (reservation.id.isEmpty || !_reservations.any((r) => r.id == reservation.id)) {
      result = await _createReservation(CreateReservationParams(reservation: reservation));
    } else {
      result = await _updateReservation(UpdateReservationParams(reservation: reservation));
    }

    result.fold(
      onSuccess: (savedReservation) {
        final index = _reservations.indexWhere((r) => r.id == savedReservation.id);
        if (index >= 0) {
          _reservations[index] = savedReservation;
        } else {
          _reservations.insert(0, savedReservation);
        }
        _reservations.sort((a, b) => b.date.compareTo(a.date));
        _state = ReservationState.loaded;
        _errorMessage = null;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = ReservationState.error;
      },
    );

    notifyListeners();
  }

  /// Delete a reservation
  Future<void> deleteReservation(String id) async {
    _state = ReservationState.loading;
    notifyListeners();

    final result = await _deleteReservation(DeleteReservationParams(id: id));

    result.fold(
      onSuccess: (_) {
        _reservations.removeWhere((r) => r.id == id);
        _state = ReservationState.loaded;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = ReservationState.error;
      },
    );

    notifyListeners();
  }

  /// Convert reservation to sale
  /// Third parameter (saleProvider) kept for backward compatibility but not used
  Future<void> convertReservationToSale(
    EggReservation reservation,
    PaymentStatus paymentStatus,
    [SaleProvider? saleProvider]
  ) async {
    if (_createSale == null) {
      _errorMessage = 'Sale creation not available';
      notifyListeners();
      return;
    }

    _state = ReservationState.loading;
    notifyListeners();

    final sale = EggSale(
      id: reservation.id,
      date: _toIsoDateString(DateTime.now()),
      quantitySold: reservation.quantity,
      pricePerEgg: reservation.pricePerEgg ?? 0.50,
      pricePerDozen: reservation.pricePerDozen ?? 6.00,
      customerName: reservation.customerName,
      customerEmail: reservation.customerEmail,
      customerPhone: reservation.customerPhone,
      notes: reservation.notes != null
          ? 'Converted from reservation on ${reservation.date}. ${reservation.notes}'
          : 'Converted from reservation on ${reservation.date}',
      paymentStatus: paymentStatus,
      paymentDate: paymentStatus == PaymentStatus.paid ||
                   paymentStatus == PaymentStatus.advance
          ? _toIsoDateString(DateTime.now())
          : null,
      isReservation: false,
      reservationNotes: null,
      createdAt: DateTime.now(),
      isLost: false,
    );

    final saleResult = await _createSale!(sales.CreateSaleParams(sale: sale));

    await saleResult.fold(
      onSuccess: (savedSale) async {
        final deleteResult = await _deleteReservation(
          DeleteReservationParams(id: reservation.id),
        );
        deleteResult.fold(
          onSuccess: (_) {
            _reservations.removeWhere((r) => r.id == reservation.id);
            _state = ReservationState.loaded;
          },
          onFailure: (failure) {
            _errorMessage = failure.message;
            _state = ReservationState.error;
          },
        );
      },
      onFailure: (failure) async {
        _errorMessage = failure.message;
        _state = ReservationState.error;
      },
    );

    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (used on logout)
  void clearData() {
    _reservations = [];
    _errorMessage = null;
    _state = ReservationState.initial;
    notifyListeners();
  }
}

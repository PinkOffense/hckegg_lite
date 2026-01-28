// lib/state/providers/reservation_provider.dart

import 'package:flutter/material.dart';
import '../../core/date_utils.dart';
import '../../models/egg_reservation.dart';
import '../../models/egg_sale.dart';
import 'sale_provider.dart';

/// Provider para gestão de reservas
/// Nota: Reservas são armazenadas localmente por enquanto
class ReservationProvider extends ChangeNotifier {
  List<EggReservation> _reservations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EggReservation> get reservations => List.unmodifiable(_reservations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carregar todas as reservas (local storage for now)
  Future<void> loadReservations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement Supabase storage when ready
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Guardar uma reserva
  Future<void> saveReservation(EggReservation reservation) async {
    try {
      final existingIndex = _reservations.indexWhere((r) => r.id == reservation.id);
      if (existingIndex != -1) {
        _reservations[existingIndex] = reservation;
      } else {
        _reservations.insert(0, reservation);
      }

      _reservations.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Eliminar uma reserva
  Future<void> deleteReservation(String id) async {
    try {
      _reservations.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Converter reserva em venda
  Future<void> convertReservationToSale(
    EggReservation reservation,
    PaymentStatus paymentStatus,
    SaleProvider saleProvider,
  ) async {
    try {
      final sale = EggSale(
        id: reservation.id,
        date: AppDateUtils.toIsoDateString(DateTime.now()),
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
        paymentDate: paymentStatus == PaymentStatus.paid || paymentStatus == PaymentStatus.advance
          ? AppDateUtils.toIsoDateString(DateTime.now())
          : null,
        isReservation: false,
        reservationNotes: null,
        createdAt: DateTime.now(),
        isLost: false,
      );

      await saleProvider.saveSale(sale);
      await deleteReservation(reservation.id);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obter reservas num intervalo de datas
  List<EggReservation> getReservationsInRange(DateTime start, DateTime end) {
    final startStr = AppDateUtils.toIsoDateString(start);
    final endStr = AppDateUtils.toIsoDateString(end);

    return _reservations.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList();
  }

  /// Limpar todos os dados (usado no logout)
  void clearData() {
    _reservations = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

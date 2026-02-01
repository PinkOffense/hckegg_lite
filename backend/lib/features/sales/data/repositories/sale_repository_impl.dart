import 'package:supabase/supabase.dart';

import '../../../../core/core.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  SaleRepositoryImpl(this._client);
  final SupabaseClient _client;
  static const _table = 'egg_sales';

  @override
  Future<Result<List<Sale>>> getSales(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      return Result.success(
        (response as List).map((j) => Sale.fromJson(j as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Sale>> getSaleById(String id) async {
    try {
      final response = await _client.from(_table).select().eq('id', id).single();
      return Result.success(Sale.fromJson(response));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Result.failure(const NotFoundFailure(message: 'Sale not found'));
      }
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Sale>>> getSalesInRange(String userId, String startDate, String endDate) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', ascending: false);
      return Result.success(
        (response as List).map((j) => Sale.fromJson(j as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Sale>>> getPendingPayments(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .eq('payment_status', 'pending')
          .eq('is_lost', false);
      return Result.success(
        (response as List).map((j) => Sale.fromJson(j as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Sale>>> getLostSales(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .eq('is_lost', true);
      return Result.success(
        (response as List).map((j) => Sale.fromJson(j as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Sale>> createSale(Sale sale) async {
    try {
      final data = {
        'user_id': sale.userId,
        'date': sale.date,
        'quantity_sold': sale.quantitySold,
        'price_per_egg': sale.pricePerEgg,
        'price_per_dozen': sale.pricePerDozen,
        'customer_name': sale.customerName,
        'customer_email': sale.customerEmail,
        'customer_phone': sale.customerPhone,
        'notes': sale.notes,
        'payment_status': sale.paymentStatus.name,
        'payment_date': sale.paymentDate,
        'is_reservation': sale.isReservation,
        'reservation_notes': sale.reservationNotes,
        'is_lost': sale.isLost,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client.from(_table).insert(data).select().single();
      return Result.success(Sale.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Sale>> updateSale(Sale sale) async {
    try {
      final data = {
        'date': sale.date,
        'quantity_sold': sale.quantitySold,
        'price_per_egg': sale.pricePerEgg,
        'price_per_dozen': sale.pricePerDozen,
        'customer_name': sale.customerName,
        'customer_email': sale.customerEmail,
        'customer_phone': sale.customerPhone,
        'notes': sale.notes,
        'payment_status': sale.paymentStatus.name,
        'payment_date': sale.paymentDate,
        'is_reservation': sale.isReservation,
        'reservation_notes': sale.reservationNotes,
        'is_lost': sale.isLost,
      };
      final response = await _client.from(_table).update(data).eq('id', sale.id).select().single();
      return Result.success(Sale.fromJson(response));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteSale(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsPaid(String id, String paymentDate) async {
    try {
      await _client.from(_table).update({
        'payment_status': 'paid',
        'payment_date': paymentDate,
      }).eq('id', id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsLost(String id) async {
    try {
      await _client.from(_table).update({'is_lost': true}).eq('id', id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<SaleStatistics>> getStatistics(String userId, String startDate, String endDate) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate);

      final sales = (response as List).map((j) => Sale.fromJson(j as Map<String, dynamic>)).toList();

      if (sales.isEmpty) {
        return const Result.success(SaleStatistics(
          totalSales: 0, totalQuantity: 0, totalRevenue: 0,
          totalPending: 0, totalLost: 0, averagePrice: 0,
        ));
      }

      var totalQuantity = 0;
      var totalRevenue = 0.0;
      var totalPending = 0.0;
      var totalLost = 0.0;

      for (final sale in sales) {
        totalQuantity += sale.quantitySold;
        totalRevenue += sale.totalAmount;
        if (sale.paymentStatus == PaymentStatus.pending) totalPending += sale.totalAmount;
        if (sale.isLost) totalLost += sale.totalAmount;
      }

      return Result.success(SaleStatistics(
        totalSales: sales.length,
        totalQuantity: totalQuantity,
        totalRevenue: totalRevenue,
        totalPending: totalPending,
        totalLost: totalLost,
        averagePrice: totalRevenue / totalQuantity,
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}

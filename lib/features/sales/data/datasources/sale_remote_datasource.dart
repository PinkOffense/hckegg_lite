import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/context/farm_context.dart';
import '../models/egg_sale_model.dart';

abstract class SaleRemoteDataSource {
  Future<List<EggSaleModel>> getSales();
  Future<EggSaleModel> getSaleById(String id);
  Future<List<EggSaleModel>> getSalesByDateRange({required String startDate, required String endDate});
  Future<List<EggSaleModel>> getPendingPayments();
  Future<List<EggSaleModel>> getLostSales();
  Future<EggSaleModel> createSale(EggSaleModel sale);
  Future<EggSaleModel> updateSale(EggSaleModel sale);
  Future<void> deleteSale(String id);
  Future<void> markAsPaid(String id, String paymentDate);
  Future<void> markAsLost(String id);
}

class SaleRemoteDataSourceImpl implements SaleRemoteDataSource {
  final SupabaseClient _client;
  static const _tableName = 'egg_sales';

  SaleRemoteDataSourceImpl(this._client);

  String? get _farmId => FarmContext().farmId;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user. Please sign in again.');
    }
    return user.id;
  }

  @override
  Future<List<EggSaleModel>> getSales() async {
    var query = _client.from(_tableName).select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query.order('date', ascending: false);
    return (response as List).map((j) => EggSaleModel.fromJson(j)).toList();
  }

  @override
  Future<EggSaleModel> getSaleById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .single();
    return EggSaleModel.fromJson(response);
  }

  @override
  Future<List<EggSaleModel>> getSalesByDateRange({required String startDate, required String endDate}) async {
    var query = _client.from(_tableName).select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', ascending: false);
    return (response as List).map((j) => EggSaleModel.fromJson(j)).toList();
  }

  @override
  Future<List<EggSaleModel>> getPendingPayments() async {
    var query = _client.from(_tableName).select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query
        .eq('payment_status', 'pending')
        .eq('is_lost', false)
        .order('date', ascending: false);
    return (response as List).map((j) => EggSaleModel.fromJson(j)).toList();
  }

  @override
  Future<List<EggSaleModel>> getLostSales() async {
    var query = _client.from(_tableName).select();

    if (_farmId != null) {
      query = query.eq('farm_id', _farmId!);
    } else {
      query = query.eq('user_id', _userId);
    }

    final response = await query
        .eq('is_lost', true)
        .order('date', ascending: false);
    return (response as List).map((j) => EggSaleModel.fromJson(j)).toList();
  }

  @override
  Future<EggSaleModel> createSale(EggSaleModel sale) async {
    final data = sale.toInsertJson(_userId);
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }

    final response = await _client
        .from(_tableName)
        .insert(data)
        .select()
        .single();
    return EggSaleModel.fromJson(response);
  }

  @override
  Future<EggSaleModel> updateSale(EggSaleModel sale) async {
    final data = sale.toInsertJson(_userId);
    if (_farmId != null) {
      data['farm_id'] = _farmId;
    }

    final response = await _client
        .from(_tableName)
        .update(data)
        .eq('id', sale.id)
        .select()
        .single();
    return EggSaleModel.fromJson(response);
  }

  @override
  Future<void> deleteSale(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  @override
  Future<void> markAsPaid(String id, String paymentDate) async {
    await _client
        .from(_tableName)
        .update({'payment_status': 'paid', 'payment_date': paymentDate})
        .eq('id', id);
  }

  @override
  Future<void> markAsLost(String id) async {
    await _client
        .from(_tableName)
        .update({'is_lost': true})
        .eq('id', id);
  }
}

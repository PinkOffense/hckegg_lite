import 'package:supabase_flutter/supabase_flutter.dart';
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

  String get _userId => _client.auth.currentUser!.id;

  @override
  Future<List<EggSaleModel>> getSales() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return (response as List).map((j) => EggSaleModel.fromJson(j)).toList();
  }

  @override
  Future<EggSaleModel> getSaleById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .single();
    return EggSaleModel.fromJson(response);
  }

  @override
  Future<List<EggSaleModel>> getSalesByDateRange({required String startDate, required String endDate}) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', ascending: false);
    return (response as List).map((j) => EggSaleModel.fromJson(j)).toList();
  }

  @override
  Future<List<EggSaleModel>> getPendingPayments() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .eq('payment_status', 'pending')
        .eq('is_lost', false)
        .order('date', ascending: false);
    return (response as List).map((j) => EggSaleModel.fromJson(j)).toList();
  }

  @override
  Future<List<EggSaleModel>> getLostSales() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .eq('is_lost', true)
        .order('date', ascending: false);
    return (response as List).map((j) => EggSaleModel.fromJson(j)).toList();
  }

  @override
  Future<EggSaleModel> createSale(EggSaleModel sale) async {
    final response = await _client
        .from(_tableName)
        .insert(sale.toInsertJson(_userId))
        .select()
        .single();
    return EggSaleModel.fromJson(response);
  }

  @override
  Future<EggSaleModel> updateSale(EggSaleModel sale) async {
    final response = await _client
        .from(_tableName)
        .update(sale.toInsertJson(_userId))
        .eq('id', sale.id)
        .eq('user_id', _userId)
        .select()
        .single();
    return EggSaleModel.fromJson(response);
  }

  @override
  Future<void> deleteSale(String id) async {
    await _client.from(_tableName).delete().eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<void> markAsPaid(String id, String paymentDate) async {
    await _client
        .from(_tableName)
        .update({'payment_status': 'paid', 'payment_date': paymentDate})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> markAsLost(String id) async {
    await _client
        .from(_tableName)
        .update({'is_lost': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }
}

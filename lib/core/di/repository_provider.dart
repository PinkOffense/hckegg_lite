// lib/core/di/repository_provider.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/remote/egg_remote_datasource.dart';
import '../../data/datasources/remote/expense_remote_datasource.dart';
import '../../data/datasources/remote/vet_remote_datasource.dart';
import '../../data/datasources/remote/sale_remote_datasource.dart';
import '../../data/repositories/egg_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/vet_repository_impl.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../domain/repositories/egg_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/vet_repository.dart';
import '../../domain/repositories/sale_repository.dart';

/// Dependency Injection Container para Repositories
/// Usa o padrão Singleton para garantir uma única instância
class RepositoryProvider {
  static RepositoryProvider? _instance;
  static RepositoryProvider get instance {
    _instance ??= RepositoryProvider._internal();
    return _instance!;
  }

  RepositoryProvider._internal();

  // Supabase client
  late final SupabaseClient _supabaseClient;

  // Datasources
  late final EggRemoteDatasource _eggDatasource;
  late final ExpenseRemoteDatasource _expenseDatasource;
  late final VetRemoteDatasource _vetDatasource;
  late final SaleRemoteDatasource _saleDatasource;

  // Repositories
  late final EggRepository _eggRepository;
  late final ExpenseRepository _expenseRepository;
  late final VetRepository _vetRepository;
  late final SaleRepository _saleRepository;

  /// Inicializar todos os repositories
  void initialize() {
    // Obter Supabase client
    _supabaseClient = Supabase.instance.client;

    // Inicializar datasources
    _eggDatasource = EggRemoteDatasource(_supabaseClient);
    _expenseDatasource = ExpenseRemoteDatasource(_supabaseClient);
    _vetDatasource = VetRemoteDatasource(_supabaseClient);
    _saleDatasource = SaleRemoteDatasource(_supabaseClient);

    // Inicializar repositories
    _eggRepository = EggRepositoryImpl(_eggDatasource);
    _expenseRepository = ExpenseRepositoryImpl(_expenseDatasource);
    _vetRepository = VetRepositoryImpl(_vetDatasource);
    _saleRepository = SaleRepositoryImpl(_saleDatasource);
  }

  // Getters para aceder aos repositories
  EggRepository get eggRepository => _eggRepository;
  ExpenseRepository get expenseRepository => _expenseRepository;
  VetRepository get vetRepository => _vetRepository;
  SaleRepository get saleRepository => _saleRepository;
}

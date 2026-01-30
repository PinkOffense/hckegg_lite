import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/datasources/egg_remote_datasource.dart';
import '../data/repositories/egg_repository_impl.dart';
import '../domain/repositories/egg_repository.dart';
import '../domain/usecases/get_egg_records.dart';
import '../domain/usecases/save_egg_record.dart';
import '../presentation/providers/egg_provider.dart';

/// Dependency injection for the Eggs feature
class EggInjection {
  final SupabaseClient _client;

  EggInjection(this._client);

  // Data sources
  EggRemoteDataSource get remoteDataSource => EggRemoteDataSourceImpl(_client);

  // Repository
  EggRepository get repository => EggRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

  // Use cases
  GetEggRecords get getEggRecords => GetEggRecords(repository);
  GetEggRecordByDate get getEggRecordByDate => GetEggRecordByDate(repository);
  CreateEggRecord get createEggRecord => CreateEggRecord(repository);
  UpdateEggRecord get updateEggRecord => UpdateEggRecord(repository);
  DeleteEggRecord get deleteEggRecord => DeleteEggRecord(repository);

  // Provider
  EggProvider get provider => EggProvider(
        getEggRecords: getEggRecords,
        getEggRecordByDate: getEggRecordByDate,
        createEggRecord: createEggRecord,
        updateEggRecord: updateEggRecord,
        deleteEggRecord: deleteEggRecord,
      );
}

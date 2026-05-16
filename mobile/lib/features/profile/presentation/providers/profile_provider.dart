import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(
    dioClient: ref.watch(dioClientProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
  );
});

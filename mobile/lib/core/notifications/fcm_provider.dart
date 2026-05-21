import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import 'fcm_service.dart';
import 'fcm_token_remote_datasource.dart';

final fcmTokenRemoteDataSourceProvider = Provider<FcmTokenRemoteDataSource>((ref) {
  return FcmTokenRemoteDataSource(dioClient: ref.watch(dioClientProvider));
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    messaging: FirebaseMessaging.instance,
    tokenDataSource: ref.watch(fcmTokenRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

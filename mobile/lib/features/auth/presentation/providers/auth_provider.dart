import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/providers/navigation_provider.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart'
    show AuthRepository, AuthRepositoryImpl;
import '../../domain/entities/user_entity.dart';

final secureStorageProvider = Provider((ref) => SecureStorage());

final dioClientProvider = Provider((ref) {
  return DioClient(secureStorage: ref.watch(secureStorageProvider));
});

final authRemoteDataSourceProvider = Provider((ref) {
  return AuthRemoteDataSourceImpl(dioClient: ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final String? error;
  final bool isAuthenticated;
  final bool registrationSuccess;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
    this.registrationSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserEntity? user,
    String? error,
    bool? isAuthenticated,
    bool? registrationSuccess,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState());

  String _errorMessage(Object e) =>
      e is ApiException ? e.message : 'Bir hata oluştu';

  /// `identifier` email **veya** telefon (Belge §3).
  Future<void> login(String identifier, String password, WidgetRef ref) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.login(identifier, password);
      // Reset tab index on successful login
      resetManagerTabIndex(ref);
      resetResidentTabIndex(ref);
      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String? phone,
  ) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.register(email, password, name, phone);
      state = state.copyWith(
        isLoading: false,
        registrationSuccess: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> join(
    String inviteCode,
    String email,
    String password,
    String name,
    String? phone,
    WidgetRef ref,
  ) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.join(
        inviteCode,
        email,
        password,
        name,
        phone,
      );
      // Reset tab index on successful join
      resetManagerTabIndex(ref);
      resetResidentTabIndex(ref);
      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  /// Uygulama açılışında SecureStorage'daki oturumu geri yükler.
  /// Splash bu future'ı bekleyip ardından yönlendirme yapar.
  Future<void> restoreSession() async {
    if (state.isAuthenticated) return;
    try {
      final user = await _authRepository.restoreSession();
      if (user != null) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          clearError: true,
        );
      } else {
        state = AuthState();
      }
    } catch (_) {
      state = AuthState();
    }
  }

  Future<void> logout(WidgetRef ref) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Reset tab index on logout
      resetManagerTabIndex(ref);
      resetResidentTabIndex(ref);
      await _authRepository.logout();
      await Future.delayed(const Duration(milliseconds: 500));
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }
}

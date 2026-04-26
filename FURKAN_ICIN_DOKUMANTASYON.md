# Furkan İçin JWT ve Flutter Entegrasyon Rehberi

## � Clean Architecture Klasör Yapısı

AIDATPANEL.md'deki yapıya göre dosyalarını şu şekilde organize et:

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart      # Base URL'ler burada
│   ├── network/
│   │   ├── dio_client.dart         # JWT interceptor burada
│   │   └── api_exception.dart
│   ├── storage/
│   │   └── secure_storage.dart     # Token saklama burada
│   └── router/
│       └── app_router.dart         # GoRouter tanımları burada
├── features/
│   └── auth/
│       ├── data/
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── models/
│       │       └── user_model.dart
│       ├── domain/
│       │   └── providers/
│       │       └── auth_provider.dart
│       └── presentation/
│           ├── login_screen.dart
│           └── register_screen.dart
└── main.dart
```

**Önemli:** JWT kodlarını `core/` katmanına koy, `features/auth/` sadece business logic içersin.

---

## � JWT Nedir? (Basit Açıklama)

JWT (JSON Web Token), kullanıcının kimliğini doğrulayan bir şifreli anahtardır. Backend'den login olunca şu şekilde bir token alırsın:

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "abc123",
    "email": "furkan@example.com",
    "name": "Furkan",
    "role": "MANAGER"
  }
}
```

**İki tip token var:**
- **Access Token**: 15 dakika geçerli. API isteklerinde kullanılır.
- **Refresh Token**: 30 gün geçerli. Access token bittiğinde yeni access token almak için kullanılır.

**Neden ikisi var?** Güvenlik. Access token kısa ömürlü olsa bile ele geçirilirse zarar sınırlı kalır. Refresh token sadece token yenileme endpoint'inde kullanılır.

---

## 🔐 1. Token Saklama (Secure Storage)

Token'ları telefonun güvenli deposunda saklayacaksın. `flutter_secure_storage` paketi kullanılacak.

### pubspec.yaml'a ekle:
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  dio: ^5.4.0
```

### Token Service Oluştur (lib/core/storage/token_storage.dart):

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  
  /// Token'ları kaydet (Login başarılı olunca çağrılır)
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
  
  /// Access token'ı oku (Her API isteğinde kullanılır)
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  /// Refresh token'ı oku (Token yenilemede kullanılır)
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  /// Access token'ı güncelle (Refresh sonrası)
  static Future<void> updateAccessToken(String newAccessToken) async {
    await _storage.write(key: _accessTokenKey, value: newAccessToken);
  }
  
  /// Tüm token'ları sil (Logout'ta kullanılır)
  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
  
  /// Token var mı kontrol et (Splash ekranında kullanılır)
  static Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }
}
```

---

## 🌐 2. API İsteklerine Token Ekleme (Dio Interceptor)

Her API isteğine otomatik olarak "Authorization: Bearer <token>" header'ı eklemelisin. Buna Interceptor denir.

### Dio Client Oluştur (lib/core/network/dio_client.dart):

```dart
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class DioClient {
  static Dio? _dio;
  
  static Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }
  
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.aidatpanel.com/api/v1',  // Backend URL
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // INTERCEPTOR: Her istekten önce çalışır
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Token'ı secure storage'dan oku
          final token = await TokenStorage.getAccessToken();
          
          // 2. Token varsa header'a ekle
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          print('📤 Request: ${options.method} ${options.path}');
          print('🔑 Token: ${token != null ? "Var" : "Yok"}');
          
          return handler.next(options);
        },
        
        onResponse: (response, handler) {
          print('✅ Response: ${response.statusCode}');
          return handler.next(response);
        },
        
        onError: (error, handler) async {
          print('❌ Error: ${error.response?.statusCode}');
          
          // 401 Unauthorized hatası mı? (Token geçersiz/süresi dolmuş)
          if (error.response?.statusCode == 401) {
            print('🔄 Token yenileniyor...');
            
            // Token'ı yenilemeyi dene
            final refreshed = await _refreshToken();
            
            if (refreshed) {
              // Yeni token ile isteği tekrar dene
              final newToken = await TokenStorage.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              
              // İsteği tekrar gönder
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } else {
              // Refresh de başarısız oldu, login'e yönlendir
              print('🚫 Refresh başarısız, login gerekli');
              // Burada Riverpod ile auth state'i güncellenir
              // Navigator.pushReplacementNamed(context, '/login');
            }
          }
          
          return handler.next(error);
        },
      ),
    );
    
    return dio;
  }
  
  /// Token yenileme fonksiyonu
  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      
      if (refreshToken == null) {
        return false;
      }
      
      // Refresh endpoint'ine istek at
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      // Yeni access token'ı kaydet
      final newAccessToken = response.data['accessToken'];
      await TokenStorage.updateAccessToken(newAccessToken);
      
      print('✅ Token yenilendi');
      return true;
    } catch (e) {
      print('❌ Token yenileme hatası: $e');
      return false;
    }
  }
}
```

---

## 🔑 3. Login Akışı

```dart
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../network/dio_client.dart';

class AuthRepository {
  final _dio = DioClient.dio;
  
  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // Başarılı yanıt
      final data = response.data;
      
      // Token'ları kaydet
      await TokenStorage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      
      // Kullanıcı bilgilerini kaydet (Riverpod state veya SharedPreferences)
      // ...
      
      return true;
    } on DioException catch (e) {
      // Hata yönetimi
      print('Login hatası: ${e.response?.data['error']}');
      return false;
    }
  }
}
```

---

## 🚪 4. Logout Akışı

```dart
class AuthRepository {
  final _dio = DioClient.dio;
  
  Future<void> logout() async {
    try {
      // Backend'e logout bildirimi (opsiyonel)
      await _dio.post('/auth/logout');
    } catch (e) {
      // Hata olsa bile devam et
    }
    
    // Token'ları temizle
    await TokenStorage.clearTokens();
    
    // Kullanıcı state'ini temizle (Riverpod)
    // ...
    
    // Login ekranına yönlendir
    // Navigator.pushReplacementNamed(context, '/login');
  }
}
```

---

## 🔄 4.1 Riverpod Auth State Management

AIDATPANEL.md'deki gibi Riverpod kullanarak auth state'i yönet.

### pubspec.yaml'a ekle:
```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
```

### Auth State Provider (lib/features/auth/domain/providers/auth_provider.dart):

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/storage/secure_storage.dart';

part 'auth_provider.g.dart';  // build_runner ile otomatik oluşturulur

/// Auth durumunu temsil eden enum
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth state class
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  
  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });
  
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Auth State Notifier
@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthRepository _authRepository;
  
  @override
  AuthState build() {
    _authRepository = ref.read(authRepositoryProvider);
    // Uygulama başlarken token kontrolü
    _checkAuth();
    return AuthState();
  }
  
  /// Token var mı kontrol et (Splash ekranında)
  Future<void> _checkAuth() async {
    final hasToken = await TokenStorage.hasTokens();
    if (hasToken) {
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }
  
  /// Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );
      
      if (result.success) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: result.user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: result.errorMessage,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Bir hata oluştu',
      );
    }
  }
  
  /// Logout
  Future<void> logout() async {
    await _authRepository.logout();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    );
  }
}

/// Global auth provider
final authProvider = authNotifierProvider;
```

### Auth Repository Provider:

```dart
// lib/features/auth/data/repositories/auth_repository_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_repository.dart';

part 'auth_repository_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository();
}
```

### Ekranda Kullanımı:

```dart
// lib/features/auth/presentation/login_screen.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auth state'i dinle
    final authState = ref.watch(authProvider);
    
    // Loading durumunda
    if (authState.status == AuthStatus.loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    // Error durumunda
    if (authState.status == AuthStatus.error) {
      // Hata mesajını göster
      print('Hata: ${authState.errorMessage}');
    }
    
    return Scaffold(
      body: Column(
        children: [
          // Email/Password inputları...
          ElevatedButton(
            onPressed: () {
              // Login butonuna basınca
              ref.read(authProvider.notifier).login(
                'email@example.com',
                'password123',
              );
            },
            child: Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🧭 5. GoRouter Navigation ve Auth Guard

AIDATPANEL.md'deki gibi GoRouter kullanarak yönlendirmeyi yap ve auth kontrolü ekle.

### pubspec.yaml'a ekle:
```yaml
dependencies:
  go_router: ^13.0.0
```

### App Router (lib/core/router/app_router.dart):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/manager_dashboard.dart';
import '../../features/dashboard/presentation/resident_dashboard.dart';

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/',
    // Her yönlendirme öncesi auth state kontrolü
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isUnauthenticated = authState.status == AuthStatus.unauthenticated;
      final isLoading = authState.status == AuthStatus.loading;
      
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isSplashRoute = state.matchedLocation == '/';
      
      // Loading durumunda hiçbir yere gitme (Splash göster)
      if (isLoading && !isSplashRoute) {
        return '/';
      }
      
      // Kimliği doğrulanmamış kullanıcı sadece login/register görebilir
      if (isUnauthenticated) {
        if (isLoginRoute || isRegisterRoute || isSplashRoute) {
          return null;  // Gitmek istediği yere gitmesine izin ver
        }
        return '/login';  // Diğer sayfalara gitmeye çalışırsa login'e yönlendir
      }
      
      // Kimliği doğrulanmış kullanıcı login/register sayfalarına gitmeye çalışırsa
      if (isAuthenticated && (isLoginRoute || isRegisterRoute || isSplashRoute)) {
        // Role göre dashboard'a yönlendir
        final isManager = authState.user?.role == 'MANAGER';
        return isManager ? '/manager' : '/resident';
      }
      
      return null;  // Normal akışa devam et
    },
    routes: [
      // Splash / Initial route
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Manager Dashboard
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboard(),
      ),
      
      // Resident Dashboard
      GoRoute(
        path: '/resident',
        builder: (context, state) => const ResidentDashboard(),
      ),
    ],
  );
});
```

### Splash Screen (lib/features/splash/splash_screen.dart):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/domain/providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authProvider).status;
    
    return Scaffold(
      body: Center(
        child: authStatus == AuthStatus.loading
            ? const CircularProgressIndicator()
            : const FlutterLogo(size: 100),
      ),
    );
  }
}
```

### Main.dart'ta Kullanımı:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'AidatPanel',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}
```

### Ekran İçinde Navigation:

```dart
import 'package:go_router/go_router.dart';

// Login başarılı olunca
context.go('/manager');  // veya '/resident'

// Logout olunca
context.go('/login');

// Register sayfasına git
context.push('/register');

// Geri git
context.pop();
```

---

## 🔄 6. Token Akış Şeması (Adım Adım)

```
┌─────────────┐     Login      ┌─────────────┐
│   Kullanıcı │ ─────────────> │   Backend   │
│  (Flutter)  │                │  (Node.js)  │
└─────────────┘                └─────────────┘
                                      │
                                      │ {accessToken, refreshToken}
                                      ▼
┌─────────────┐              ┌─────────────┐
│   Kullanıcı │ <─────────── │   Backend   │
│  (Flutter)  │              └─────────────┘
└─────────────┘                      │
     │                               │
     │ Token'ları                    │
     │ Secure Storage'a kaydet       │
     ▼                               │
┌─────────────┐                      │
│  Her API    │                      │
│  isteğinde  │                      │
│  otomatik   │                      │
│  Authorization: Bearer <token>    │
│  header'ı ekle                     │
└─────────────┘                      │
     │                               │
     │ 401 hatası                    │
     │ (Token süresi doldu)         │
     ▼                               │
┌─────────────┐      /refresh      │
│  Refresh    │ ───────────────────> │
│  Token ile  │                      │
│  yeni       │ <────────────────── │
│  Access     │  {accessToken}       │
│  Token al   │                      │
└─────────────┘                      │
     │                               │
     ▼                               ▼
┌─────────────┐              ┌─────────────┐
│  İsteği     │              │   Backend   │
│  yeni       │ ───────────> │             │
│  token ile  │              │             │
│  tekrar dene│              │             │
└─────────────┘              └─────────────┘
```

---

## 🎯 7. Önemli Notlar

### A. Token Süreleri
- **Access Token**: 15 dakika (Backend'de ayarlanmış)
- **Refresh Token**: 30 gün (Backend'de ayarlanmış)

Kullanıcı 15 dakika işlem yapmazsa, bir sonraki istekte otomatik olarak refresh çalışır. Kullanıcı bunu hissetmez.

### B. Secure Storage Avantajı
- iOS: Keychain kullanır (en güvenli)
- Android: EncryptedSharedPreferences kullanır
- Normal SharedPreferences'tan farkı: Şifrelenmiş saklar

### C. Hata Senaryoları

| Durum | Ne Olur | Çözüm |
|-------|---------|-------|
| Access token süresi doldu | 401 hatası | Interceptor otomatik refresh yapar |
| Refresh token süresi doldu | Refresh başarısız | Kullanıcı login ekranına yönlendirilir |
| İnternet yok | Timeout hatası | "İnternet bağlantınızı kontrol edin" mesajı |
| Yanlış şifre | 400 hatası | "Email veya şifre hatalı" mesajı |

---

## 📝 8. Test Senaryoları

### Test 1: Login
1. Login ekranına git
2. Email/şifre gir
3. Login butonuna bas
4. Başarılı yanıt bekleyen: Token'lar kaydedilmeli

### Test 2: Korumalı API
1. Login ol
2. Bina listeleme API'sini çağır
3. Header'da Authorization olmalı
4. 200 OK gelmeli

### Test 3: Token Yenileme
1. Login ol
2. 15 dakika bekle (veya backend'de token süresini 1 saniye yap test için)
3. Yeni bir API isteği yap
4. Otomatik olarak refresh çalışmalı, istek başarılı olmalı

### Test 4: Logout
1. Login ol
2. Logout butonuna bas
3. Token'lar silinmeli
4. Login ekranına yönlendirilmeli

---

## 🆘 Yardım İhtiyacı Olursa

Bu dokümanı anlamazsan:
1. `flutter_secure_storage` örneklerine bak
2. Dio interceptor dokümantasyonunu oku
3. JWT nedir videosu izle (YouTube'da "JWT explained" ara)

Soruların olursa Abdullah'a sor, backend tarafını o yönetiyor.

---

**Hazırlayan:** Backend (Abdullah)  
**Hedef:** Mobil (Furkan)  
**Amaç:** JWT mantığını ve Flutter implementasyonunu anlamak

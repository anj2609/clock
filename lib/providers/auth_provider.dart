import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.authStateChanges;
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return AuthNotifier(firebaseService);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _firebaseService;

  AuthNotifier(this._firebaseService) : super(const AsyncData<void>(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading<void>();
    try {
      await _firebaseService.signIn(email, password);
      state = const AsyncData<void>(null);
    } catch (e) {
      state = AsyncError<void>(e, StackTrace.current);
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading<void>();
    try {
      await _firebaseService.register(email, password);
      state = const AsyncData<void>(null);
    } catch (e) {
      state = AsyncError<void>(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading<void>();
    try {
      await _firebaseService.signOut();
      state = const AsyncData<void>(null);
    } catch (e) {
      state = AsyncError<void>(e, StackTrace.current);
    }
  }
}

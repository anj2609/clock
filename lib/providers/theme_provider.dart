import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  return ThemeNotifier(firebaseService, uid);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final FirebaseService _firebaseService;
  final String? _uid;

  ThemeNotifier(this._firebaseService, this._uid) : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    if (_uid == null) return;
    final isDark = await _firebaseService.getThemePreference(_uid);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    if (_uid != null) {
      await _firebaseService.setThemePreference(_uid, !isDark);
    }
  }
}

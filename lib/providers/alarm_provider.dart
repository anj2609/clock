import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/alarm.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

final hiveAlarmBoxProvider = Provider<Box<Alarm>>((ref) {
  return Hive.box<Alarm>(AppConstants.hiveBoxName);
});

final alarmStreamProvider = StreamProvider<List<Alarm>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<Alarm>[]);
      }
      return firebaseService.alarmsStream(user.uid);
    },
    loading: () => Stream.value(<Alarm>[]),
    error: (_, __) => Stream.value(<Alarm>[]),
  );
});

final alarmNotifierProvider =
    StateNotifierProvider<AlarmNotifier, AsyncValue<void>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final authState = ref.watch(authStateProvider);
  final hiveBox = ref.watch(hiveAlarmBoxProvider);
  final uid = authState.valueOrNull?.uid;
  return AlarmNotifier(firebaseService, hiveBox, uid);
});

class AlarmNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseService _firebaseService;
  final Box<Alarm> _hiveBox;
  final String? _uid;

  AlarmNotifier(this._firebaseService, this._hiveBox, this._uid)
      : super(const AsyncData<void>(null));

  Future<void> addAlarm(Alarm alarm) async {
    if (_uid == null) return;
    state = const AsyncLoading<void>();
    try {
      await _hiveBox.put(alarm.id, alarm);
      await _firebaseService.addAlarm(_uid, alarm);
      await NotificationService.scheduleAlarm(alarm);
      state = const AsyncData<void>(null);
    } catch (e) {
      state = AsyncError<void>(e, StackTrace.current);
    }
  }

  Future<void> updateAlarm(Alarm alarm) async {
    if (_uid == null) return;
    state = const AsyncLoading<void>();
    try {
      await _hiveBox.put(alarm.id, alarm);
      await _firebaseService.updateAlarm(_uid, alarm);
      await NotificationService.cancelAlarm(alarm.id);
      if (alarm.isEnabled) {
        await NotificationService.scheduleAlarm(alarm);
      }
      state = const AsyncData<void>(null);
    } catch (e) {
      state = AsyncError<void>(e, StackTrace.current);
    }
  }

  Future<void> deleteAlarm(String alarmId) async {
    if (_uid == null) return;
    state = const AsyncLoading<void>();
    try {
      await _hiveBox.delete(alarmId);
      await _firebaseService.deleteAlarm(_uid, alarmId);
      await NotificationService.cancelAlarm(alarmId);
      state = const AsyncData<void>(null);
    } catch (e) {
      state = AsyncError<void>(e, StackTrace.current);
    }
  }

  Future<void> syncFromFirestore() async {
    if (_uid == null) return;
    try {
      final alarms = await _firebaseService.fetchAllAlarms(_uid);
      for (final alarm in alarms) {
        await _hiveBox.put(alarm.id, alarm);
      }
    } catch (_) {}
  }
}

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
});

final connectivityListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
    final wasOffline = previous?.valueOrNull == false;
    final isNowOnline = next.valueOrNull == true;

    if (wasOffline && isNowOnline) {
      ref.read(alarmNotifierProvider.notifier).syncFromFirestore();
    }
  });
});

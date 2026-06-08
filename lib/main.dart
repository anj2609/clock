import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'models/alarm.dart';
import 'providers/auth_provider.dart';
import 'providers/alarm_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_edit_alarm_screen.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(AlarmAdapter());
  await Hive.openBox<Alarm>(AppConstants.hiveBoxName);

  await NotificationService.initialize();

  runApp(const ProviderScope(child: AlarmClockApp()));
}

class AlarmClockApp extends ConsumerWidget {
  const AlarmClockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    ref.watch(connectivityListenerProvider);

    final router = GoRouter(
      initialLocation: AppConstants.routeLogin,
      refreshListenable: RouterNotifier(ref),
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);

        return authState.when(
          data: (user) {
            final isOnAuth = state.matchedLocation == AppConstants.routeLogin ||
                state.matchedLocation == AppConstants.routeRegister;

            if (user == null && !isOnAuth) {
              return AppConstants.routeLogin;
            }

            if (user != null && isOnAuth) {
              return AppConstants.routeHome;
            }

            return null;
          },
          loading: () => null,
          error: (_, __) => AppConstants.routeLogin,
        );
      },
      routes: [
        GoRoute(
          path: AppConstants.routeLogin,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppConstants.routeRegister,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppConstants.routeHome,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAddAlarm,
          builder: (context, state) => const AddEditAlarmScreen(),
        ),
        GoRoute(
          path: '${AppConstants.routeEditAlarm}/:alarmId',
          builder: (context, state) => AddEditAlarmScreen(
            alarmId: state.pathParameters['alarmId'],
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6750A4),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6750A4),
        fontFamily: 'Roboto',
      ),
      routerConfig: router,
    );
  }
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

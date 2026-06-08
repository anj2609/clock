class AppConstants {
  static const String appName = 'Alarm Clock';
  static const String hiveBoxName = 'alarms_box';
  static const String themeBoxName = 'theme_box';
  static const String isDarkModeKey = 'isDarkMode';

  static const String firestoreUsersCollection = 'users';
  static const String firestoreAlarmsCollection = 'alarms';
  static const String firestoreSettingsCollection = 'settings';
  static const String firestoreThemeDocument = 'theme';

  static const String notificationChannelId = 'alarm_channel';
  static const String notificationChannelName = 'Alarm Notifications';
  static const String notificationChannelDescription =
      'Channel for alarm notifications';

  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeAddAlarm = '/add-alarm';
  static const String routeEditAlarm = '/edit-alarm';

  static const String loginTitle = 'Login';
  static const String registerTitle = 'Register';
  static const String homeTitle = appName;
  static const String addAlarmTitle = 'Add Alarm';
  static const String editAlarmTitle = 'Edit Alarm';

  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String loginButton = 'Login';
  static const String registerButton = 'Register';
  static const String logoutButton = 'Logout';
  static const String saveButton = 'Save';
  static const String deleteButton = 'Delete';
  static const String retryButton = 'Retry';
  static const String cancelButton = 'Cancel';

  static const String noAccountText = "Don't have an account? Register";
  static const String hasAccountText = 'Already have an account? Login';
  static const String noAlarmsText = 'No alarms yet. Tap + to add one.';
  static const String labelHint = 'Alarm Label';
  static const String snoozeLabel = 'Snooze';
  static const String repeatLabel = 'Repeat';
  static const String deleteConfirmTitle = 'Delete Alarm';
  static const String deleteConfirmMessage =
      'Are you sure you want to delete this alarm?';

  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorWrongPassword =
      'Incorrect password. Please try again.';
  static const String errorUserNotFound =
      'No account found with this email. Please register.';
  static const String errorWeakPassword =
      'Password is too weak. Use at least 6 characters.';
  static const String errorEmailAlreadyInUse =
      'An account already exists with this email.';
  static const String errorNetworkRequest =
      'Network error. Please check your connection and try again.';
  static const String errorUnknown =
      'An unexpected error occurred. Please try again.';
  static const String errorEmptyEmail = 'Email cannot be empty.';
  static const String errorEmptyPassword = 'Password cannot be empty.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorEmptyLabel = 'Label cannot be empty.';
  static const String errorLoadingAlarms = 'Failed to load alarms.';
  static const String errorSavingAlarm = 'Failed to save alarm.';
  static const String errorDeletingAlarm = 'Failed to delete alarm.';

  static const List<String> dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<int> snoozeOptions = [5, 10, 15, 20];
}

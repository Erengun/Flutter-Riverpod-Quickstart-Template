/// The Permission areas this app checks. The backend decides them; keep
/// these in step with what it sends. A route declares its area on `SGRoute`.
abstract final class AppAreas {
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String reports = 'reports';
}

/// The component keys this app gives rules to (`hidden`, `readonly`,
/// `disabled`).
abstract final class AppComponents {
  static const String profileEmail = 'profile.email';
  static const String profileEdit = 'profile.edit';
  static const String settingsDeleteAccount = 'settings.deleteAccount';
}

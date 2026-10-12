// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Production Boilerplate';

  @override
  String get authCreateAccount => 'Create an account';

  @override
  String get authCredentialsRequired => 'Please enter your email and password.';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authEmailInvalid => 'Please enter a valid email address';

  @override
  String get authEmailRequired => 'Please enter an email address';

  @override
  String get authLoginButton => 'Login';

  @override
  String get authLoginFailed => 'Wrong email or password.';

  @override
  String get authLoginSubtitle => 'You can login with your email and password';

  @override
  String get authLoginTitle => 'Login';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authRegisterButton => 'Register';

  @override
  String get authRegisterCancel => 'Cancel';

  @override
  String get authRegisterTitle => 'New Profile';

  @override
  String get authUsernameHint => 'Enter your username';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authWelcome => 'Welcome to the app';

  @override
  String demoAreaBody(String area) {
    return 'You can see this page because your permissions include the \"$area\" area.';
  }

  @override
  String get demoComponentRulesTitle => 'Component rules';

  @override
  String get demoDeleteAccountHidden => 'Delete account (hidden)';

  @override
  String get demoEditProfileDisabled => 'Edit profile (disabled)';

  @override
  String get demoEmailReadonly => 'Email (read-only)';

  @override
  String get demoOrdersTitle => 'Orders';

  @override
  String get demoPermissionsTitle => 'Permission demo';

  @override
  String get demoProfileTitle => 'Profile';

  @override
  String get demoReportsTitle => 'Reports';

  @override
  String get demoSettingsTitle => 'Settings';

  @override
  String get homeBottomNavFirst => 'Home';

  @override
  String get homeBottomNavSecond => 'Info';

  @override
  String get homeInfo => 'Info';

  @override
  String get homeIntro => 'Hi, I am Eren 👋🏽';

  @override
  String get homeMenuTitle => 'Menu';

  @override
  String get homeMore => 'Learn More';

  @override
  String get homeThemeMode => 'Theme Mode';

  @override
  String get homeThemeModeDark => 'Dark';

  @override
  String get homeThemeModeLight => 'Light';

  @override
  String get homeThemeModeSystem => 'System';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeToggleLanguage => 'Change Language';

  @override
  String get homeToggleTheme => 'Change Theme';
}

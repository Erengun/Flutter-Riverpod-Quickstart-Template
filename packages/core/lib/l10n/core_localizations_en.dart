// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CoreLocalizationsEn extends CoreLocalizations {
  CoreLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorConnection =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorNoPermission => 'You don\'t have permission to do this.';

  @override
  String get errorNotFound => 'What you\'re looking for couldn\'t be found.';

  @override
  String get errorRetry => 'Try again';

  @override
  String get errorServer =>
      'Something went wrong on our side. Please try again later.';

  @override
  String get errorSomethingWentWrong =>
      'Something went wrong. Please try again.';

  @override
  String get errorTimeout => 'The request took too long. Please try again.';

  @override
  String get noPermissionBody =>
      'You don\'t have permission to view this page.';

  @override
  String get noPermissionTitle => 'No access';

  @override
  String get pageBackHome => 'Back to home';

  @override
  String get underConstructionBody =>
      'This page isn\'t ready yet. Please check back later.';

  @override
  String get underConstructionTitle => 'Coming soon';

  @override
  String get updateBodyOptional =>
      'A new version is available. Would you like to update now?';

  @override
  String get updateBodyRequired =>
      'A new version is required to keep using the app. Please update now.';

  @override
  String get updateButtonIgnore => 'Ignore';

  @override
  String get updateButtonLater => 'Later';

  @override
  String get updateButtonUpdate => 'Update';

  @override
  String get updateTitle => 'Update available';
}

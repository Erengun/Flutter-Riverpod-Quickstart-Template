import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter Production Boilerplate'**
  String get appTitle;

  /// Body of the permission demo screens.
  ///
  /// In en, this message translates to:
  /// **'You can see this page because your permissions include the \"{area}\" area.'**
  String demoAreaBody(String area);

  /// No description provided for @demoComponentRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Component rules'**
  String get demoComponentRulesTitle;

  /// No description provided for @demoDeleteAccountHidden.
  ///
  /// In en, this message translates to:
  /// **'Delete account (hidden)'**
  String get demoDeleteAccountHidden;

  /// No description provided for @demoEditProfileDisabled.
  ///
  /// In en, this message translates to:
  /// **'Edit profile (disabled)'**
  String get demoEditProfileDisabled;

  /// No description provided for @demoEmailReadonly.
  ///
  /// In en, this message translates to:
  /// **'Email (read-only)'**
  String get demoEmailReadonly;

  /// No description provided for @demoOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get demoOrdersTitle;

  /// No description provided for @demoPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission demo'**
  String get demoPermissionsTitle;

  /// No description provided for @demoProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get demoProfileTitle;

  /// No description provided for @demoReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get demoReportsTitle;

  /// No description provided for @demoSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get demoSettingsTitle;

  /// No description provided for @homeBottomNavFirst.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeBottomNavFirst;

  /// No description provided for @homeBottomNavSecond.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get homeBottomNavSecond;

  /// No description provided for @homeInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get homeInfo;

  /// No description provided for @homeIntro.
  ///
  /// In en, this message translates to:
  /// **'Hi, I am Eren 👋🏽'**
  String get homeIntro;

  /// No description provided for @homeMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenuTitle;

  /// No description provided for @homeMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get homeMore;

  /// No description provided for @homeThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get homeThemeMode;

  /// No description provided for @homeThemeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get homeThemeModeDark;

  /// No description provided for @homeThemeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get homeThemeModeLight;

  /// No description provided for @homeThemeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get homeThemeModeSystem;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeToggleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get homeToggleLanguage;

  /// No description provided for @homeToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get homeToggleTheme;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

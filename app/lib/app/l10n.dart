import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// Every localizations delegate the app uses. `MaterialApp` and the tests
/// both read this list.
///
/// - [AppLocalizations.localizationsDelegates]: the app's strings plus
///   flutter_localizations' Material, Cupertino and Widgets delegates.
/// - [CoreLocalizations.delegate]: Core's strings.
/// - material_ui's [GlobalMaterialLocalizations.delegates]: material_ui
///   widgets read their own `MaterialLocalizations` type, which the
///   flutter_localizations delegates don't provide.
///
/// A Module with strings adds its delegate here, and removing the Module
/// removes the line.
const List<LocalizationsDelegate<Object?>> appLocalizationsDelegates =
    <LocalizationsDelegate<Object?>>[
      ...AppLocalizations.localizationsDelegates,
      CoreLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];

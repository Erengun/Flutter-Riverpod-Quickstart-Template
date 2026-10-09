import 'package:flutter/widgets.dart';
import 'package:upgrader/upgrader.dart';

import '../../l10n/core_localizations.dart';

/// The update dialog's text, from Core's localizations instead of upgrader's
/// built-in translations.
class KonteynerUpgraderMessages extends UpgraderMessages {
  KonteynerUpgraderMessages(this.strings, {required this.updateRequired})
    : super(code: strings.localeName);

  /// Core's strings in [locale], or in English when Core has no strings for
  /// it. Usable without a `BuildContext`.
  factory KonteynerUpgraderMessages.forLocale(
    Locale locale, {
    required bool updateRequired,
  }) {
    final Locale supported = CoreLocalizations.delegate.isSupported(locale)
        ? locale
        : const Locale('en');
    return KonteynerUpgraderMessages(
      lookupCoreLocalizations(supported),
      updateRequired: updateRequired,
    );
  }

  final CoreLocalizations strings;

  /// Whether this is a hard update, which changes the body.
  final bool updateRequired;

  @override
  String get title => strings.updateTitle;

  @override
  String get body =>
      updateRequired ? strings.updateBodyRequired : strings.updateBodyOptional;

  @override
  String get buttonTitleUpdate => strings.updateButtonUpdate;

  @override
  String get buttonTitleIgnore => strings.updateButtonIgnore;

  @override
  String get buttonTitleLater => strings.updateButtonLater;

  /// The bodies already ask the question, so there is no separate prompt.
  @override
  String get prompt => '';

  /// Release notes are not shown.
  @override
  String get releaseNotes => '';
}

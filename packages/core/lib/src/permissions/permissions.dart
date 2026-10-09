import 'dart:convert';

import 'package:flutter/foundation.dart';

/// An override for one control inside a granted Permission area. A control
/// without a rule is unrestricted.
enum ComponentState {
  /// Removed from the screen.
  hidden,

  /// Shown but not interactive, and not greyed out.
  readonly,

  /// Shown greyed out.
  disabled,
}

/// What the signed-in user may open and use, flattened from whatever the
/// backend sends by the auth Feature's `loadPermissions` hook.
///
/// - [areas]: the Permission areas the backend granted. A missing area means
///   no access.
/// - [components]: rules for single controls, by component key.
@immutable
class Permissions {
  const Permissions({
    this.areas = const <String>{},
    this.components = const <String, ComponentState>{},
  }) : allowsEverything = false;

  const Permissions._unrestricted()
    : areas = const <String>{},
      components = const <String, ComponentState>{},
      allowsEverything = true;

  /// No areas and no rules: every check fails. A signed-out user has these.
  static const Permissions none = Permissions();

  /// Every area is granted. Used when the app has no `loadPermissions`
  /// hook, so apps without permissions pay nothing.
  static const Permissions unrestricted = Permissions._unrestricted();

  final Set<String> areas;

  final Map<String, ComponentState> components;

  /// Whether every area is granted ([unrestricted]).
  final bool allowsEverything;

  /// Whether [area] is granted.
  bool can(String area) => allowsEverything || areas.contains(area);

  /// The rule for the control [componentKey], or `null` when it has none
  /// (unrestricted). [unrestricted] has no rules.
  ComponentState? stateOf(String componentKey) => components[componentKey];

  /// The JSON string Core saves in the encrypted session box.
  String encode() => jsonEncode(<String, Object>{
    'areas': areas.toList(),
    'components': <String, String>{
      for (final MapEntry<String, ComponentState> entry in components.entries)
        entry.key: entry.value.name,
    },
  });

  /// Reads a string written by [encode]; `null` when it is malformed.
  static Permissions? decode(String source) {
    try {
      final Object? json = jsonDecode(source);
      if (json is! Map<String, Object?>) return null;
      final Object? areas = json['areas'];
      final Object? components = json['components'];
      if (areas is! List<Object?> || components is! Map<String, Object?>) {
        return null;
      }
      return Permissions(
        areas: <String>{...areas.cast<String>()},
        components: <String, ComponentState>{
          for (final MapEntry<String, Object?> entry in components.entries)
            entry.key: ComponentState.values.byName(entry.value! as String),
        },
      );
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Permissions &&
      other.allowsEverything == allowsEverything &&
      setEquals(other.areas, areas) &&
      mapEquals(other.components, components);

  @override
  int get hashCode => Object.hash(
    allowsEverything,
    Object.hashAllUnordered(areas),
    Object.hashAllUnordered(
      components.entries.map(
        (MapEntry<String, ComponentState> entry) =>
            Object.hash(entry.key, entry.value),
      ),
    ),
  );

  @override
  String toString() => allowsEverything
      ? 'Permissions.unrestricted'
      : 'Permissions(areas: $areas, components: $components)';
}

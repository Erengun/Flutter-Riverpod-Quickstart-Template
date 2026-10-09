import 'package:flutter/foundation.dart';

/// One entry [PermissionMenu.filter] kept.
@immutable
class PermissionMenuEntry {
  const PermissionMenuEntry({
    required this.key,
    required this.location,
    required this.underConstruction,
  });

  /// The entry's Permission area key.
  final String key;

  /// Where the entry leads: its route, or the under-construction page.
  final String location;

  /// Whether the key has no screen yet, so [location] is the
  /// under-construction page.
  final bool underConstruction;

  @override
  bool operator ==(Object other) =>
      other is PermissionMenuEntry &&
      other.key == key &&
      other.location == location &&
      other.underConstruction == underConstruction;

  @override
  int get hashCode => Object.hash(key, location, underConstruction);

  @override
  String toString() =>
      'PermissionMenuEntry($key → $location'
      '${underConstruction ? ', under construction' : ''})';
}

/// The menu filter: which menu entries the user sees and where they lead.
///
/// Menu entries are Permission area keys. [routes] maps each key that has
/// a screen to its route; a key without one leads to
/// [underConstructionPath] (Core's `UnderConstructionPage`). The app
/// decides whether its keys are a fixed list or come from the backend's
/// tree, and how the menu looks.
@immutable
class PermissionMenu {
  const PermissionMenu({
    required this.routes,
    required this.underConstructionPath,
  });

  /// Route location by area key, for the keys that have a screen.
  final Map<String, String> routes;

  /// Where a key without a screen leads.
  final String underConstructionPath;

  /// Where [key] leads.
  String locationOf(String key) => routes[key] ?? underConstructionPath;

  /// The entries of [keys], in order, whose area [can] grants. In a widget,
  /// pass `(String area) => ref.watch(canProvider(area))`: it rebuilds when
  /// the permissions change, keeps every entry out while they are not known
  /// yet, and lets debug builds check the keys.
  List<PermissionMenuEntry> filter(
    Iterable<String> keys, {
    required bool Function(String area) can,
  }) {
    return <PermissionMenuEntry>[
      for (final String key in keys)
        if (can(key))
          PermissionMenuEntry(
            key: key,
            location: locationOf(key),
            underConstruction: !routes.containsKey(key),
          ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is PermissionMenu &&
      other.underConstructionPath == underConstructionPath &&
      mapEquals(other.routes, routes);

  @override
  int get hashCode => Object.hash(
    underConstructionPath,
    Object.hashAllUnordered(
      routes.entries.map(
        (MapEntry<String, String> entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );
}

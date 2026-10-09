import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Permissions', () {
    const Permissions permissions = Permissions(
      areas: <String>{'orders', 'reports'},
      components: <String, ComponentState>{
        'orders.delete': ComponentState.hidden,
        'orders.price': ComponentState.readonly,
        'reports.export': ComponentState.disabled,
      },
    );

    test('grants only the areas it holds', () {
      expect(permissions.can('orders'), isTrue);
      expect(permissions.can('settings'), isFalse);
      expect(Permissions.none.can('orders'), isFalse);
    });

    test('unrestricted grants every area', () {
      expect(Permissions.unrestricted.can('anything'), isTrue);
      expect(Permissions.unrestricted, isNot(Permissions.none));
    });

    test('survives encode and decode', () {
      expect(Permissions.decode(permissions.encode()), permissions);
      expect(Permissions.decode(Permissions.none.encode()), Permissions.none);
    });

    test('a malformed saved copy decodes to null', () {
      expect(Permissions.decode('{not json'), isNull);
      expect(Permissions.decode('[]'), isNull);
      expect(
        Permissions.decode('{"areas": ["a"], "components": {"b": "nope"}}'),
        isNull,
      );
    });
  });

  group('permissionRedirect', () {
    const Permissions permissions = Permissions(areas: <String>{'orders'});

    String? redirect(Permissions? permissions, String location, String? area) {
      return permissionRedirect(
        permissions,
        location,
        area: area,
        splashPath: '/splash',
        noPermissionPath: '/no-permission',
      );
    }

    test('lets a route without an area through', () {
      expect(redirect(null, '/home', null), isNull);
      expect(redirect(Permissions.none, '/home', null), isNull);
    });

    test('lets a granted area through', () {
      expect(redirect(permissions, '/orders', 'orders'), isNull);
      expect(redirect(Permissions.unrestricted, '/x', 'x'), isNull);
    });

    test('sends a missing area to the no-permission page', () {
      expect(redirect(permissions, '/reports', 'reports'), '/no-permission');
      expect(redirect(Permissions.none, '/orders', 'orders'), '/no-permission');
    });

    test('holds a guarded route on the splash while not known', () {
      expect(redirect(null, '/orders', 'orders'), '/splash');
    });

    test('with the uri, the held route goes along as from', () {
      String? held(String location) => permissionRedirect(
        null,
        Uri.parse(location).path,
        area: 'orders',
        splashPath: '/splash',
        noPermissionPath: '/no-permission',
        uri: Uri.parse(location),
      );
      expect(
        held('/orders/7?tab=items'),
        '/splash?from=%2Forders%2F7%3Ftab%3Ditems',
      );
      expect(held('/orders'), '/splash?from=%2Forders');
    });
  });

  group('sessionRedirect then permissionRedirect', () {
    const AsyncValue<Session?> signedIn = AsyncData<Session?>(
      Session(accessToken: 'abc'),
    );
    const Map<String, String> areas = <String, String>{
      '/orders': 'orders',
      '/reports': 'reports',
    };

    /// Follows the redirects from [location] as go_router does, failing on
    /// a loop, and returns where the user ends up.
    String follow(
      AsyncValue<Session?> session,
      Permissions? permissions,
      String location,
    ) {
      final List<String> seen = <String>[location];
      String current = location;
      while (true) {
        final Uri uri = Uri.parse(current);
        final String? next =
            sessionRedirect(
              session,
              uri.path,
              splashPath: '/splash',
              loginPath: '/login',
              homePath: '/home',
              uri: uri,
              holdOnSplash: permissions == null,
            ) ??
            permissionRedirect(
              permissions,
              uri.path,
              area: areas[uri.path],
              splashPath: '/splash',
              noPermissionPath: '/no-permission',
              uri: uri,
            );
        if (next == null) return current;
        if (seen.contains(next)) {
          fail('redirect loop: ${<String>[...seen, next]}');
        }
        seen.add(next);
        current = next;
      }
    }

    test('a guarded route waits on the splash until permissions load', () {
      const String held = '/splash?from=%2Forders%2F7%3Ftab%3Ditems';
      expect(
        follow(const AsyncLoading<Session?>(), null, '/orders/7?tab=items'),
        held,
      );
      // The session landed; the permissions are still unknown.
      expect(follow(signedIn, null, held), held);
      expect(follow(signedIn, null, '/orders'), '/splash?from=%2Forders');
    });

    test('continues to from once the permissions are known', () {
      const Permissions permissions = Permissions(areas: <String>{'orders'});
      expect(
        follow(signedIn, permissions, '/splash?from=%2Forders'),
        '/orders',
      );
      expect(
        follow(signedIn, permissions, '/splash?from=%2Freports'),
        '/no-permission',
      );
    });

    test('an open route never waits for the permissions', () {
      expect(follow(signedIn, null, '/home'), '/home');
      expect(follow(signedIn, null, '/splash'), '/home');
    });

    test('an unsafe from is ignored', () {
      expect(
        follow(signedIn, null, '/splash?from=%2F%2Fevil.example'),
        '/home',
      );
      expect(
        follow(
          signedIn,
          Permissions.none,
          '/splash?from=https%3A%2F%2Fevil.example',
        ),
        '/home',
      );
    });
  });
}

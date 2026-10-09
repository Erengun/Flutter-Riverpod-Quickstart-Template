import 'package:core/core.dart';
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
  });
}

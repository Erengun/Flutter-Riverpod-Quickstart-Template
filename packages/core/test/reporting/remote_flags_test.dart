import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NoopRemoteFlags returns every fallback', () async {
    const RemoteFlags flags = NoopRemoteFlags();

    expect(flags.getBool('flag', fallback: true), isTrue);
    expect(flags.getInt('count', fallback: 7), 7);
    expect(flags.getString('text', fallback: 'x'), 'x');
    await flags.refresh();
    expect(await flags.onChanged.isEmpty, isTrue);
  });
}

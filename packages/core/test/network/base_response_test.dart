import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

BaseResponse<String> _envelope({
  bool? success,
  String? errorMessage,
  String? message,
}) {
  return BaseResponse<String>(
    success: success,
    data: 'payload',
    errorMessage: errorMessage,
    message: message,
    statusCode: '200',
  );
}

void main() {
  group('unwrap', () {
    test('returns data when success is true', () {
      expect(_envelope(success: true).unwrap(), 'payload');
    });

    test('success false or missing is business', () {
      expect(
        () => _envelope(success: false).unwrap(),
        throwsA(isA<ApiBusinessException>()),
      );
      expect(() => _envelope().unwrap(), throwsA(isA<ApiBusinessException>()));
    });

    test('the business message is errorMessage ?? message', () {
      ApiException caught(BaseResponse<String> response) {
        try {
          response.unwrap();
        } on ApiException catch (error) {
          return error;
        }
        fail('expected an ApiException');
      }

      expect(caught(_envelope(errorMessage: 'a', message: 'b')).message, 'a');
      expect(caught(_envelope(message: 'b')).message, 'b');
      expect(caught(_envelope()).message, isNull);
    });
  });

  test('fromJson decodes the generic data', () {
    final BaseResponse<int> response = BaseResponse<int>.fromJson(
      <String, dynamic>{
        'success': true,
        'data': 3,
        'errorMessage': null,
        'message': 'ok',
        'statusCode': '200',
      },
      (Object? json) => json! as int,
    );
    expect(response.data, 3);
    expect(response.success, isTrue);
  });

  test('envelopeErrorMessage reads errorMessage ?? message from a body', () {
    expect(
      envelopeErrorMessage(<String, Object?>{
        'errorMessage': 'a',
        'message': 'b',
      }),
      'a',
    );
    expect(envelopeErrorMessage(<String, Object?>{'message': 'b'}), 'b');
    expect(envelopeErrorMessage(<String, Object?>{'error': 'x'}), isNull);
    expect(envelopeErrorMessage('plain text'), isNull);
    expect(envelopeErrorMessage(null), isNull);
  });

  test('normalizeRequestPath replaces ids and drops the query', () {
    expect(
      normalizeRequestPath(Uri.parse('https://x.dev/api/users/42?q=secret')),
      '/api/users/:id',
    );
    expect(
      normalizeRequestPath(
        Uri.parse('https://x.dev/a/3F2504E0-4F89-11D3-9A0C-0305E82C3301/b'),
      ),
      '/a/:id/b',
    );
    expect(normalizeRequestPath(Uri.parse('https://x.dev')), '/');
  });
}

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('Core ships English and Turkish', () {
    expect(
      CoreLocalizations.supportedLocales,
      containsAll(<Locale>[const Locale('en'), const Locale('tr')]),
    );
    expect(CoreLocalizations.supportedLocales.first, const Locale('en'));
  });

  test('error and session messages use the decided wording', () {
    final CoreLocalizations en = lookupCoreLocalizations(const Locale('en'));
    final CoreLocalizations tr = lookupCoreLocalizations(const Locale('tr'));

    expect(
      en.errorConnection,
      'No internet connection. Check your connection and try again.',
    );
    expect(en.errorTimeout, 'The request took too long. Please try again.');
    expect(en.errorNoPermission, "You don't have permission to do this.");
    expect(en.errorNotFound, "What you're looking for couldn't be found.");
    expect(
      en.errorServer,
      'Something went wrong on our side. Please try again later.',
    );
    expect(en.errorSomethingWentWrong, 'Something went wrong. Please try again.');
    expect(
      en.authSessionExpired,
      'Your session has expired. Please sign in again.',
    );

    expect(
      tr.errorConnection,
      'İnternet bağlantısı yok. Bağlantınızı kontrol edip tekrar deneyin.',
    );
    expect(tr.errorTimeout, 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    expect(tr.errorNoPermission, 'Bu işlem için yetkiniz yok.');
    expect(tr.errorNotFound, 'Aradığınız içerik bulunamadı.');
    expect(
      tr.errorServer,
      'Sunucuda bir sorun oluştu. Lütfen daha sonra tekrar deneyin.',
    );
    expect(
      tr.errorSomethingWentWrong,
      'Bir şeyler ters gitti. Lütfen tekrar deneyin.',
    );
    expect(
      tr.authSessionExpired,
      'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.',
    );
  });
}
